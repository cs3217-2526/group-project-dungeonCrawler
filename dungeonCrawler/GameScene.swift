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
    /// uiLayer stays fixed — joystick HUD lives here.
    private let uiLayer    = SKNode()

    // MARK: - Adapters
    private var renderingBackend: SpriteKitRenderingAdapter!
    private var cameraAdapter: SpriteKitCameraAdapter!
    private var tileAdapter: SpriteKitTileMapAdapter!

    // MARK: - Level service (owns the graph and room lifecycle)
    private var levelOrchestrator: LevelOrchestrator!

    // MARK: - Command queues
    private let commandQueues = CommandQueues()

    // MARK: - Input provider
    private let touchInput = TouchJoystickInputProvider()
    private lazy var reloadInput = SwitchWeaponButtonInputProvider(commandQueues: commandQueues)

    // MARK: - Collision Events
    let collisionEvents  = CollisionEventBuffer()
    let destructionQueue = DestructionQueue()

    // MARK: - Joystick HUD nodes (drawn directly in SpriteKit, above game world)
    private let leftBase    = SKShapeNode(circleOfRadius: 50)
    private let leftHandle  = SKShapeNode(circleOfRadius: 22)
    private let rightBase   = SKShapeNode(circleOfRadius: 50)
    private let rightHandle = SKShapeNode(circleOfRadius: 22)

    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.addSubview(reloadInput.button)
        NSLayoutConstraint.activate([
            reloadInput.button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.07),
            reloadInput.button.heightAnchor.constraint(equalTo: reloadInput.button.widthAnchor),
            reloadInput.button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.2),
            reloadInput.button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.bounds.height * 0.05),
        ])
    }

    override func sceneDidLoad() {
        self.lastUpdateTime = 0

        let background = SKSpriteNode(color: .darkGray, size: self.size)
        background.position = .zero
        background.zPosition = -1
        addChild(background)

        addChild(worldLayer)
        addChild(uiLayer)

        view?.isMultipleTouchEnabled = true

        setupJoystickHUD()
        setupSystems()
        startLevel(1)
    }

    // MARK: - Joystick HUD setup

    private func setupJoystickHUD() {
        for base in [leftBase, rightBase] {
            base.strokeColor = SKColor(white: 1, alpha: 0.35)
            base.fillColor   = SKColor(white: 1, alpha: 0.08)
            base.lineWidth   = 2
            base.zPosition   = 50
            base.isHidden    = true
            uiLayer.addChild(base)
        }

        for handle in [leftHandle, rightHandle] {
            handle.strokeColor = SKColor(white: 1, alpha: 0.6)
            handle.fillColor   = SKColor(white: 1, alpha: 0.25)
            handle.lineWidth   = 2
            handle.zPosition   = 51
            handle.isHidden    = true
            uiLayer.addChild(handle)
        }
    }

    // MARK: - System wiring

    private func setupSystems() {
        renderingBackend = SpriteKitRenderingAdapter(worldLayer: worldLayer)
        cameraAdapter    = SpriteKitCameraAdapter(worldLayer: worldLayer)

        let registryLoader = TileRegistryLoader()
        tileAdapter = SpriteKitTileMapAdapter(worldLayer: worldLayer, registryLoader: registryLoader)

        // Build the dungeon manager with swappable strategies.
        // To change dungeon shape or interior style, replace these two lines only.
        var constructionConfig = BoxRoomConstructor.Config()
        constructionConfig.renderVisualSprites = false  // tilemap handles floor/wall visuals
        levelOrchestrator = LevelOrchestrator(
            layoutStrategy:  LinearDungeonLayout(
                roomCount:  3,
                enemyPool:  [.charger, .mummy, .ranger]
            ),
            roomConstructor: BoxRoomConstructor(config: constructionConfig)
        )
        levelOrchestrator.tileMapRenderer = tileAdapter

        systemManager.register(LevelTransitionSystem(orchestrator: levelOrchestrator))
        commandQueues.register(SwitchWeaponCommand.self)
        systemManager.register(InputSystem(joyStickInputProvider: touchInput, commandQueues: commandQueues))
        systemManager.register(EnemyAISystem())
        systemManager.register(HealthSystem())
        systemManager.register(MovementSystem())
        systemManager.register(CollisionSystem(events: collisionEvents, destructionQueue: destructionQueue))
        systemManager.register(WeaponSystem())
        systemManager.register(KnockbackSystem())
        systemManager.register(CameraSystem())
        systemManager.register(RenderSystem(backend: renderingBackend))
        systemManager.register(ProjectileSystem(events: collisionEvents, destructionQueue: destructionQueue))
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
        }
    }

    // MARK: - Touch forwarding

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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

    // MARK: - Joystick HUD update

    private func updateJoystickHUD() {
        updateStick(
            base: leftBase, handle: leftHandle,
            basePos: touchInput.leftBasePosition,
            handlePos: touchInput.leftHandlePosition
        )
        updateStick(
            base: rightBase, handle: rightHandle,
            basePos: touchInput.rightBasePosition,
            handlePos: touchInput.rightHandlePosition
        )
    }

    private func updateStick(
        base: SKShapeNode,
        handle: SKShapeNode,
        basePos: CGPoint?,
        handlePos: CGPoint?
    ) {
        if let bp = basePos, let hp = handlePos {
            base.isHidden   = false
            handle.isHidden = false
            base.position   = uiKitToSpriteKit(bp)
            handle.position = uiKitToSpriteKit(hp)
        } else {
            base.isHidden   = true
            handle.isHidden = true
        }
    }

    /// Converts a UIKit point (origin top-left) to SpriteKit space (origin centre).
    private func uiKitToSpriteKit(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x - size.width  / 2,
            y: size.height / 2 - point.y
        )
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 20.0)
        lastUpdateTime = currentTime

        systemManager.update(deltaTime: deltaTime, world: world)

        // Apply camera viewport to worldLayer after ECS update.
        if let cameraEntity = world.entities(with: ViewportComponent.self).first,
           let viewport = world.getComponent(type: ViewportComponent.self, for: cameraEntity) {
            cameraAdapter.apply(viewport: viewport, screenCenter: .zero)
        }

        updateJoystickHUD()
    }
}
