//
//  SpriteKitRenderingAdapter.swift
//  dungeonCrawler
//

import SpriteKit

// MARK: - SpriteKit implementation

/// Manages SKSpriteNodes inside `worldLayer`. Sprites are positioned in world space;
/// the adapter shifts `worldLayer` each frame to implement camera movement.
public final class SpriteKitRenderingAdapter: RenderingBackend {

    private weak var worldLayer: SKNode?
    private var nodeRegistry: [Entity: SKSpriteNode] = [:]

    public init(worldLayer: SKNode) {
        self.worldLayer = worldLayer
    }

    public func syncNode(
        for entity: Entity,
        transform: TransformComponent,
        sprite: SpriteComponent,
        velocity: VelocityComponent?
    ) {
        guard let worldLayer else { return }
        let node = node(for: entity, sprite: sprite, in: worldLayer)

        node.position = transform.cgPoint
        node.zRotation = 0

        var flipFactor: CGFloat = node.xScale < 0 ? -1.0 : 1.0
        if let velocity {
            if velocity.linear.x > 0 {
                flipFactor = 1.0
            } else if velocity.linear.x < 0 {
                flipFactor = -1.0
            }
        }

        node.xScale = CGFloat(transform.scale) * flipFactor
        node.yScale = CGFloat(transform.scale)

        node.color = SKColor(
            red:   CGFloat(sprite.tintRed),
            green: CGFloat(sprite.tintGreen),
            blue:  CGFloat(sprite.tintBlue),
            alpha: CGFloat(sprite.tintAlpha)
        )
        node.colorBlendFactor = (sprite.tintRed == 1 && sprite.tintGreen == 1 &&
                                 sprite.tintBlue == 1) ? 0.0 : 1.0
    }

    public func removeNode(for entity: Entity) {
        nodeRegistry[entity]?.removeFromParent()
        nodeRegistry[entity] = nil
    }

    // MARK: - Node lifecycle

    private func node(for entity: Entity, sprite: SpriteComponent, in parent: SKNode) -> SKSpriteNode {
        if let existing = nodeRegistry[entity] { return existing }

        let texture = SKTexture(imageNamed: sprite.textureName)
        let node = SKSpriteNode(texture: texture)
        node.name = "entity_\(entity.id)"
        node.zPosition = 1
        parent.addChild(node)
        nodeRegistry[entity] = node
        return node
    }
}
