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
    /// uiLayer stays fixed — joystick, HUD, and overlays live here.
    private let uiLayer = SKNode()

    // MARK: - Adapters
    private var renderingBackend: SpriteKitRenderingAdapter!
    private var cameraAdapter:    SpriteKitCameraAdapter!
    private var tileAdapter:      SpriteKitTileMapAdapter!
    private var hudBackend:       SpriteKitHUDAdapter!
    private var joystickBackend:  SpriteKitJoystickAdapter!

    // MARK: - Level service (owns the graph and room lifecycle)
    private var levelOrchestrator: LevelOrchestrator!

    // MARK: - Overlay presenter
    private lazy var overlayPresenter = GameOverlayPresenter(uiLayer: uiLayer, size: size)

    // MARK: - Command queues
    private let commandQueues = CommandQueues()

    // MARK: - Input providers
    private lazy var touchInput        = TouchJoystickInputProvider(commandQueues: commandQueues)
    private lazy var switchWeaponInput = SwitchWeaponButtonInputProvider(commandQueues: commandQueues)
    private lazy var dropWeaponInput   = DropWeaponButtonInputProvider(commandQueues: commandQueues)
    private lazy var pickupInput       = PickupButtonInputProvider(commandQueues: commandQueues)

    // MARK: - Game state
    private var isGameOver     = false
    private var isLevelCleared = false
    /// Counts down the particle-effect duration before showing the level-clear overlay.
    private var soulClearCountdown: Double = 0

    // MARK: - Dungeon selection (set by LevelSelectScene before presenting)
    var dungeonDefinition: DungeonDefinition? = DungeonLibrary.all.first

    // MARK: - Character animation (loaded once, reused across restarts)
    private var characterSheet: CharacterSheet?

    // MARK: - Events
    private let collisionEvents      = CollisionEventBuffer()
    private let destructionQueue     = DestructionQueue()
    private let playerDeathEvent     = PlayerDeathEvent()
    private let bossRoomClearedEvent = BossRoomClearedEvent()
    private let levelClearedEvent    = LevelClearedEvent()

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func sceneDidLoad() {
        lastUpdateTime = 0
        let background = SKSpriteNode(color: .darkGray, size: self.size)
        background.position  = .zero
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
        setupInputButtons(in: view)
    }

    // MARK: - System wiring

    private func setupSystems() {
        renderingBackend = SpriteKitRenderingAdapter(worldLayer: worldLayer)
        cameraAdapter    = SpriteKitCameraAdapter(worldLayer: worldLayer)
        hudBackend       = SpriteKitHUDAdapter(uiLayer: uiLayer, screenSize: size)
        joystickBackend  = SpriteKitJoystickAdapter(uiLayer: uiLayer, screenSize: size)

        let registryLoader = TileRegistryLoader()
        tileAdapter = SpriteKitTileMapAdapter(worldLayer: worldLayer, registryLoader: registryLoader)

        guard let dungeonDefinition else {
            fatalError("No DungeonDefinition available.")
        }

        var constructionConfig = BoxRoomConstructor.Config()
        constructionConfig.renderVisualSprites = false

        levelOrchestrator = LevelOrchestrator(
            layoutStrategy:  dungeonDefinition.layoutStrategy,
            roomConstructor: BoxRoomConstructor(config: constructionConfig)
        )
        levelOrchestrator.currentTheme    = dungeonDefinition.theme
        levelOrchestrator.tileMapRenderer = tileAdapter

        systemManager.register(RoomTransitionSystem(orchestrator: levelOrchestrator))
        systemManager.register(RoomClearSystem(orchestrator: levelOrchestrator, bossRoomClearedEvent: bossRoomClearedEvent))

        if let sheet = CharacterSheetLoader().load() {
            characterSheet = sheet
            sheet.textureRegistry.forEach { renderingBackend.registerTexture($0.value, forName: $0.key) }
            systemManager.register(AnimationSystem())
            systemManager.register(LoopingAnimationSystem())
            systemManager.register(ParticleEffectSystem(destructionQueue: destructionQueue))
            systemManager.register(SoulPickupSystem(
                destructionQueue:      destructionQueue,
                levelClearedEvent:     levelClearedEvent,
                particleFrameNames:    sheet.particleEffectFrameNames,
                particleFrameDuration: sheet.particleEffectFrameDuration
            ))
        }

        commandQueues.register(SwitchWeaponCommand.self)
        commandQueues.register(DropWeaponCommand.self)
        commandQueues.register(PickupCommand.self)
        commandQueues.register(MoveCommand.self)
        commandQueues.register(AimCommand.self)
        commandQueues.register(FireCommand.self)
        commandQueues.register(JoystickRenderCommand.self)

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
        systemManager.register(SlowSystem())
    }

    // MARK: - Level management

    private func startLevel(_ levelNumber: Int) {
        levelOrchestrator.loadLevel(levelNumber, world: world)

        if world.entities(with: ViewportComponent.self).isEmpty {
            let cameraEntity = world.createEntity()
            world.addComponent(component: ViewportComponent(), to: cameraEntity)
        }

        if let player = world.entities(with: PlayerTagComponent.self).first,
           let sheet  = characterSheet {
            world.addComponent(component: CameraFocusComponent(), to: player)
            world.getComponent(type: TransformComponent.self, for: player)?.scale = 70.0 / 16.0
            world.addComponent(component: AnimationComponent(
                animations:    sheet.animations,
                frameDuration: sheet.frameDuration
            ), to: player)
        }
    }

    // MARK: - Input buttons layout

    private func setupInputButtons(in view: SKView) {
        view.addSubview(switchWeaponInput.button)
        view.addSubview(dropWeaponInput.button)
        view.addSubview(pickupInput.button)

        NSLayoutConstraint.activate([
            switchWeaponInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            switchWeaponInput.button.heightAnchor.constraint(equalTo: switchWeaponInput.button.widthAnchor),
            switchWeaponInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.2),
            switchWeaponInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.05),

            dropWeaponInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            dropWeaponInput.button.heightAnchor.constraint(equalTo: switchWeaponInput.button.widthAnchor),
            dropWeaponInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.1),
            dropWeaponInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.2),

            pickupInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            pickupInput.button.heightAnchor.constraint(equalTo: switchWeaponInput.button.widthAnchor),
            pickupInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.2),
            pickupInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.2),
        ])
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

        if playerDeathEvent.playerDied {
            handleGameOver()
            return
        }

        handleBossRoomCleared()
        handleSoulCountdown(deltaTime: deltaTime)

        if let cameraEntity = world.entities(with: ViewportComponent.self).first,
           let viewport = world.getComponent(type: ViewportComponent.self, for: cameraEntity) {
            cameraAdapter.apply(viewport: viewport, screenCenter: .zero)
        }
    }

    // MARK: - Event handling

    private func handleBossRoomCleared() {
        guard let center = bossRoomClearedEvent.roomCenter,
              let roomID = bossRoomClearedEvent.roomID,
              let sheet  = characterSheet else { return }
        bossRoomClearedEvent.consume()
        SoulEntityFactory(
            position:               center,
            roomID:                 roomID,
            animationFrameNames:    sheet.soulFrameNames,
            animationFrameDuration: sheet.soulFrameDuration
        ).make(in: world)
    }

    private func handleSoulCountdown(deltaTime: Double) {
        if levelClearedEvent.triggered {
            levelClearedEvent.reset()
            let frames   = characterSheet?.particleEffectFrameNames.count ?? 1
            let duration = characterSheet?.particleEffectFrameDuration   ?? 0.3
            soulClearCountdown = Double(frames) * duration
        }

        guard soulClearCountdown > 0 else { return }
        soulClearCountdown -= deltaTime
        if soulClearCountdown <= 0 {
            soulClearCountdown = 0
            handleLevelCleared()
        }
    }

    // MARK: - Game Over

    private func handleGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        isPaused   = true
        overlayPresenter.showGameOver()
    }

    private func restartGame() {
        overlayPresenter.removeGameOver()
        isGameOver     = false
        isLevelCleared = false
        playerDeathEvent.reset()
        isPaused       = false
        lastUpdateTime = 0
        world.destroyAllEntities()
        startLevel(1)
    }

    // MARK: - Level Cleared

    private func handleLevelCleared() {
        guard !isLevelCleared else { return }
        isLevelCleared = true
        switchWeaponInput.button.isHidden = true
        dropWeaponInput.button.isHidden   = true
        pickupInput.button.isHidden       = true
        isPaused = true
        overlayPresenter.showLevelCleared { [weak self] in
            self?.returnToLevelSelect()
        }
    }

    private func returnToLevelSelect() {
        guard let view else { return }
        let scene = LevelSelectScene(size: size)
        scene.anchorPoint = anchorPoint
        scene.scaleMode   = scaleMode
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.6))
    }
}
