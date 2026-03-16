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

    // MARK: - Input provider
    private let touchInput = TouchJoystickInputProvider()
    
    // MARK: - Joystick HUD nodes (drawn directly in SpriteKit, above game world)
    // Two pairs: base ring + handle knob, one per thumb.
    // Nodes are added/removed each frame based on whether the thumb is active.
    private let leftBase   = SKShapeNode(circleOfRadius: 50)
    private let leftHandle = SKShapeNode(circleOfRadius: 22)
    private let rightBase  = SKShapeNode(circleOfRadius: 50)
    private let rightHandle = SKShapeNode(circleOfRadius: 22)
    
    private var lastUpdateTime : TimeInterval = 0
  
    override func sceneDidLoad() {
        
        self.lastUpdateTime = 0
        
        let background = SKSpriteNode(color: .darkGray, size: self.size)
        background.position = .zero
        background.zPosition = -1
        addChild(background)

        view?.isMultipleTouchEnabled = true
        
        setupJoystickHUD()
        setupSystems()
        spawnInitialEntities()
    }
    
    // MARK: - Joystick HUD setup

    private func setupJoystickHUD() {
        // Base ring — semi-transparent white outline
        for base in [leftBase, rightBase] {
            base.strokeColor = SKColor(white: 1, alpha: 0.35)
            base.fillColor   = SKColor(white: 1, alpha: 0.08)
            base.lineWidth   = 2
            base.zPosition   = 50
            base.isHidden    = true
            addChild(base)
        }

        // Handle knob — slightly more opaque
        for handle in [leftHandle, rightHandle] {
            handle.strokeColor = SKColor(white: 1, alpha: 0.6)
            handle.fillColor   = SKColor(white: 1, alpha: 0.25)
            handle.lineWidth   = 2
            handle.zPosition   = 51
            handle.isHidden    = true
            addChild(handle)
        }
    }

    
    // MARK: - System wiring

    private func setupSystems() {
        systemManager.register(InputSystem(inputProvider: touchInput))
        systemManager.register(MovementSystem())
        systemManager.register(CollisionSystem())
        systemManager.register(RenderSystem(scene: self))
    }

    // MARK: - Entity spawning

    private func spawnInitialEntities() {
        let shortSide   = Float(min(size.width, size.height))
        let knightScale = shortSide * 0.04 / 48.0   // assumes 48pt base texture size
        EntityFactory.makePlayer(in: world, at: .zero, scale: knightScale)
    }

    // MARK: - Touch forwarding
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }
        touchInput.touchesBegan(touches, in: view)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }
        touchInput.touchesMoved(touches, in: view)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }
        touchInput.touchesEnded(touches, in: view)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }
        touchInput.touchesCancelled(touches, in: view)
    }
    
    // MARK: - Joystick HUD update
    // Called every frame. Positions nodes based on current touch state.

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
            y: size.height / 2 - point.y   // flip Y
        )
    }
    
    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 20.0)
        lastUpdateTime = currentTime

        systemManager.update(deltaTime: deltaTime, world: world)
        updateJoystickHUD()
    }
}
