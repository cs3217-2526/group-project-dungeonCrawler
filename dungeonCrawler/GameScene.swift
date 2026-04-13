//
//  GameScene.swift
//  dungeonCrawler
//
//  Created by Letian on 9/3/26.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    // MARK: - ECS core
    private let world         = World()
    private let systemManager = SystemManager()

    // MARK: - Scene layers
    /// worldLayer moves each frame to implement camera tracking.
    private let worldLayer = SKNode()
    /// uiLayer stays fixed — joystick, HUD lives here.
    private let uiLayer    = SKNode()

    // MARK: - Adapters
    private var renderingBackend: SpriteKitRenderingAdapter!
    private var cameraAdapter:    SpriteKitCameraAdapter!
    private var tileAdapter:      SpriteKitTileMapAdapter!
    private var hudBackend:       SpriteKitHUDAdapter!
    private var joystickBackend:  SpriteKitJoystickAdapter!

    // MARK: - Level service (owns the graph and room lifecycle)
    private var levelOrchestrator: LevelOrchestrator!

    // MARK: - Command queues
    private let commandQueues = CommandQueues()

    // MARK: - Input provider
    private lazy var touchInput = TouchJoystickInputProvider(commandQueues: commandQueues)
    private lazy var switchWeaponInput = SwitchWeaponButtonInputProvider(commandQueues: commandQueues)
    private lazy var dropWeaponInput = DropWeaponButtonInputProvider(commandQueues: commandQueues)
    private lazy var pickupInput = PickupButtonInputProvider(commandQueues: commandQueues)
    
    // MARK: - Game state
    private var isGameOver = false

    // MARK: - Dungeon selection (set by LevelSelectScene before presenting)
    var dungeonDefinition: DungeonDefinition? = DungeonLibrary.all.first

    // MARK: - Character animation (loaded once, reused across restarts)
    private var characterSheet: CharacterSheet?

    // MARK: - Collision Events
    let collisionEvents  = CollisionEventBuffer()
    let destructionQueue = DestructionQueue()
    let playerDeathEvent = PlayerDeathEvent()

    private var lastUpdateTime: TimeInterval = 0

    override func sceneDidLoad() {
        self.lastUpdateTime = 0

        let background = SKSpriteNode(color: .darkGray, size: self.size)
        background.position = .zero
        background.zPosition = -1
        addChild(background)
        addChild(worldLayer)
        addChild(uiLayer)
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        view.isMultipleTouchEnabled = true

        setupSystems()
        startLevel(1)

        view.addSubview(switchWeaponInput.button)
        view.addSubview(dropWeaponInput.button)
        view.addSubview(pickupInput.button)
        NSLayoutConstraint.activate([
            switchWeaponInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            switchWeaponInput.button.heightAnchor.constraint(equalTo: switchWeaponInput.button.widthAnchor),
            switchWeaponInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.2),
            switchWeaponInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.05),
        ])
        NSLayoutConstraint.activate([
            dropWeaponInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            dropWeaponInput.button.heightAnchor.constraint(equalTo: switchWeaponInput.button.widthAnchor),
            dropWeaponInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.1),
            dropWeaponInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.2),
        ])
        NSLayoutConstraint.activate([
            pickupInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            pickupInput.button.heightAnchor.constraint(equalTo: switchWeaponInput.button.widthAnchor),
            pickupInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.2),
            pickupInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.2),
        ])
    }

    // MARK: - System wiring

    private func setupSystems() {
        renderingBackend = SpriteKitRenderingAdapter(worldLayer: worldLayer)
        cameraAdapter    = SpriteKitCameraAdapter(worldLayer: worldLayer)
        hudBackend       = SpriteKitHUDAdapter(uiLayer: uiLayer, screenSize: size)
        joystickBackend  = SpriteKitJoystickAdapter(uiLayer: uiLayer, screenSize: size)

        let registryLoader = TileRegistryLoader()
        tileAdapter = SpriteKitTileMapAdapter(worldLayer: worldLayer, registryLoader: registryLoader)

        // Build the dungeon manager using the selected dungeon's layout + theme.
        var constructionConfig = BoxRoomConstructor.Config()
        constructionConfig.renderVisualSprites = false  // tilemap handles visuals
        
        guard let dungeonDefinition = dungeonDefinition else {
            fatalError("No DungeonDefinition available.")
        }
        
        levelOrchestrator = LevelOrchestrator(
            layoutStrategy:  dungeonDefinition.layoutStrategy,
            roomConstructor: BoxRoomConstructor(config: constructionConfig)
        )
        levelOrchestrator.currentTheme    = dungeonDefinition.theme
        levelOrchestrator.tileMapRenderer = tileAdapter

        systemManager.register(RoomTransitionSystem(orchestrator: levelOrchestrator))
        systemManager.register(RoomClearSystem(orchestrator: levelOrchestrator))

        // Load character spritesheet and register animation textures with the rendering backend
        let sheetLoader = CharacterSheetLoader()
        if let sheet = sheetLoader.load() {
            characterSheet = sheet
            for (name, texture) in sheet.textureRegistry {
                renderingBackend.registerTexture(texture, forName: name)
            }
            systemManager.register(AnimationSystem())
        }
        commandQueues.register(SwitchWeaponCommand.self)
        commandQueues.register(DropWeaponCommand.self)
        commandQueues.register(PickupCommand.self)
        commandQueues.register(MoveCommand.self)
        commandQueues.register(AimCommand.self)
        commandQueues.register(FireCommand.self)
        commandQueues.register(JoystickRenderCommand.self)

        // Systems
        systemManager.register(InputSystem(commandQueues: commandQueues))
        systemManager.register(WeaponDropSystem(commandQueues: commandQueues))
        systemManager.register(PickupSystem(commandQueues: commandQueues))
        systemManager.register(EnemyAISystem())
        systemManager.register(HealthSystem(destructionQueue: destructionQueue, playerDeathEvent: playerDeathEvent))
        systemManager.register(ManaSystem())
        systemManager.register(MovementSystem())
        systemManager.register(CollisionSystem(events: collisionEvents, destructionQueue: destructionQueue))
        systemManager.register(DamageSystem(events: collisionEvents, destructionQueue: destructionQueue))
        systemManager.register(InvincibilitySystem())
        systemManager.register(WeaponSystem())
        systemManager.register(KnockbackSystem())
        systemManager.register(CameraSystem())
        systemManager.register(HUDSystem(backend: hudBackend, joystickBackend: joystickBackend, commandQueues: commandQueues))
        systemManager.register(RenderSystem(backend: renderingBackend))
        systemManager.register(ProjectileSystem(events: collisionEvents, destructionQueue: destructionQueue))
        systemManager.register(FireEffectsSystem(destructionQueue: destructionQueue))
    }

    // MARK: - Level management

    private func startLevel(_ levelNumber: Int) {
        levelOrchestrator.loadLevel(levelNumber, world: world)

        // Camera entity — ViewportComponent holds live camera state.
        if world.entities(with: ViewportComponent.self).isEmpty {
            let cameraEntity = world.createEntity()
            world.addComponent(component: ViewportComponent(), to: cameraEntity)
        }
        if let player = world.entities(with: PlayerTagComponent.self).first {
            world.addComponent(component: CameraFocusComponent(), to: player)

            // Attach animation if the character sheet loaded successfully
            if let sheet = characterSheet {
                // Scale 16px character frames
                world.getComponent(type: TransformComponent.self, for: player)?.scale = 70.0 / 16.0
                world.addComponent(component: AnimationComponent(
                    animations:    sheet.animations,
                    frameDuration: sheet.frameDuration
                ), to: player)
            }
        }
    }
    
    // MARK: - Game Over
     
    private func handleGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
 
        // Freeze the game loop
        isPaused = true
 
        // Overlay — dark semi-transparent panel
        let overlay = SKSpriteNode(color: SKColor(white: 0, alpha: 0.65), size: size)
        overlay.position = .zero
        overlay.zPosition = 100
        overlay.name = "gameOverOverlay"
        uiLayer.addChild(overlay)
 
        // "GAME OVER" label
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "GAME OVER"
        titleLabel.fontSize = 52
        titleLabel.fontColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 60)
        titleLabel.zPosition = 101
        overlay.addChild(titleLabel)
 
        // "Tap to Restart" hint
        let hintLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        hintLabel.text = "Tap to restart"
        hintLabel.fontSize = 24
        hintLabel.fontColor = .white
        hintLabel.verticalAlignmentMode = .center
        hintLabel.position = CGPoint(x: 0, y: -20)
        hintLabel.zPosition = 101
        overlay.addChild(hintLabel)
    }
 
    private func restartGame() {
        // Clean up overlay
        uiLayer.childNode(withName: "gameOverOverlay")?.removeFromParent()
 
        // Reset state flags
        isGameOver = false
        playerDeathEvent.reset()
        isPaused = false
        lastUpdateTime = 0
 
        // Tear down all ECS entities and reload
        world.destroyAllEntities()
        startLevel(1)
    }

    // MARK: - Touch forwarding

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
            return
        }
        guard let view else { return }
        touchInput.touchesBegan(touches, in: view)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        touchInput.touchesMoved(touches, in: view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        touchInput.touchesEnded(touches, in: view)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        touchInput.touchesCancelled(touches, in: view)
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 20.0)
        lastUpdateTime = currentTime

        systemManager.update(deltaTime: deltaTime, world: world)
        
        // Check for player death after all systems have run this frame
        if playerDeathEvent.playerDied {
            handleGameOver()
            return
        }

        // Apply camera viewport to worldLayer after ECS update.
        if let cameraEntity = world.entities(with: ViewportComponent.self).first,
           let viewport = world.getComponent(type: ViewportComponent.self, for: cameraEntity) {
            cameraAdapter.apply(viewport: viewport, screenCenter: .zero)
        }
    }
}
