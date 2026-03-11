//
//  RenderSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import SpriteKit
import simd

public final class RenderSystem: System {

    public let priority: Int = 100

    // MARK: - Internal state

    private weak var scene: SKScene?

    /// Maps each entity to its managed SKSpriteNode.
    private var _nodeRegistry: [Entity: SKSpriteNode] = [:]

    public init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Update

    public func update(deltaTime: Double, world: World) {
        guard let scene = scene else { return }

        let renderables = world.entities(
            with: TransformComponent.self,
            and: SpriteComponent.self
        )

        var seenEntities = Set<Entity>()

        for (entity, transform, sprite) in renderables {
            seenEntities.insert(entity)

            let node = nodeFor(entity: entity, sprite: sprite, in: scene)

            // Sync position and rotation from ECS → SpriteKit.
            // We do NOT animate here — that would introduce lag. Direct assignment
            // only; SpriteKit actions / animations layer on top if needed.
            node.position = transform.cgPoint
            node.zRotation = CGFloat(transform.rotation)
            node.xScale    = CGFloat(transform.scale)
            node.yScale    = CGFloat(transform.scale)

            // Sync tint.
            node.color = SKColor(
                red:   CGFloat(sprite.tintRed),
                green: CGFloat(sprite.tintGreen),
                blue:  CGFloat(sprite.tintBlue),
                alpha: CGFloat(sprite.tintAlpha)
            )
            node.colorBlendFactor = (sprite.tintRed == 1 && sprite.tintGreen == 1 &&
                                     sprite.tintBlue == 1) ? 0.0 : 1.0
        }

        // Remove nodes for entities that no longer have both components
        // (destroyed entities, or SpriteComponent removed mid-game).
        let staleEntities = Set(_nodeRegistry.keys).subtracting(seenEntities)
        for entity in staleEntities {
            _nodeRegistry[entity]?.removeFromParent()
            _nodeRegistry[entity] = nil
        }
    }

    // MARK: - Node lifecycle

    private func nodeFor(entity: Entity, sprite: SpriteComponent, in scene: SKScene) -> SKSpriteNode {
        if let existing = _nodeRegistry[entity] { return existing }

        let texture = SKTexture(imageNamed: sprite.textureName)
        let node = SKSpriteNode(texture: texture)
        node.name = "entity_\(entity.id)"

        // Future: add a `zLayer` field to SpriteComponent.
        node.zPosition = 1

        scene.addChild(node)
        _nodeRegistry[entity] = node
        return node
    }
}
