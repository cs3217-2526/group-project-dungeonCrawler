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
    private var textureCache: [String: SKTexture] = [:]

    public init(worldLayer: SKNode) {
        self.worldLayer = worldLayer
    }

    /// Pre-registers a texture under `name` so it is used instead of `SKTexture(imageNamed:)`.
    /// Call this for every frame extracted from a spritesheet before the first render tick.
    public func registerTexture(_ texture: SKTexture, forName name: String) {
        textureCache[name] = texture
    }

    public func syncNode(
        for entity: Entity,
        transform: TransformComponent,
        sprite: SpriteComponent,
        facing: FacingComponent?,
        velocity: VelocityComponent?,
        health: HealthComponent?,
        hasDirectionalAnimation: Bool
    ) {
        guard let worldLayer else { return }
        let node = node(for: entity, sprite: sprite, in: worldLayer)

        node.position = transform.cgPoint
        node.zRotation = CGFloat(transform.rotation)

        // Entities whose textures already encode left/right (directional animations)
        // must not be xScale-mirrored — the frame itself carries the facing.
        var flipFactor: CGFloat = node.xScale < 0 ? -1.0 : 1.0
        if hasDirectionalAnimation { // character
            flipFactor = 1.0
        } else if let facing {
            flipFactor = facing.facing.isLeft ? -1.0 : 1.0
        } else if let velocity, velocity.linear.x != 0 {
            flipFactor = velocity.linear.x > 0 ? 1.0 : -1.0
            if sprite.layer == RenderLayer.weaponBack || sprite.layer == RenderLayer.weaponFront {
                sprite.layer = velocity.linear.x > 0 ? .weaponBack : .weaponFront
            }
        }

        node.xScale = CGFloat(transform.scale) * flipFactor
        node.yScale = CGFloat(transform.scale)
        node.zPosition = sprite.layer.rawValue
        
        let baseColor: SIMD4<Float>
        let isColourContent: Bool
        switch sprite.content {
        case .solidColor(let color):
            baseColor = color
            isColourContent = true
        case .texture(let name):
            // Check if the texture name changed (e.g., from AnimationSystem advancing a frame)
            // and only trigger a SpriteKit texture change if it's actually different.
            let tex = textureCache[name] ?? SKTexture(imageNamed: name)
            if node.texture !== tex { node.texture = tex }
            baseColor = SIMD4<Float>(1, 1, 1, 1)
            isColourContent = false
        }
        
        let finalColor = baseColor * sprite.tint
        
        node.color = SKColor(
            red:   CGFloat(finalColor.x),
            green: CGFloat(finalColor.y),
            blue:  CGFloat(finalColor.z),
            alpha: CGFloat(finalColor.w)
        )
        
        // Color blend should be absolute for solids, or conditional for textures based on tint
        let isWhiteTint = sprite.tint.x == 1 && sprite.tint.y == 1 && sprite.tint.z == 1
        node.colorBlendFactor = isColourContent ? 1.0 : (isWhiteTint ? 0.0 : 1.0)
        
        if let health {
            let maxHP = health.value.max ?? health.value.base
            let ratio = maxHP > 0 ? health.value.current / maxHP : 0
            updateHealthBar(on: node, ratio: CGFloat(ratio))
        } else {
            node.childNode(withName: "healthBarBG")?.removeFromParent()
        }
    }

    public func removeNode(for entity: Entity) {
        nodeRegistry[entity]?.removeFromParent()
        nodeRegistry[entity] = nil
    }

    // MARK: - Node lifecycle

    private func node(for entity: Entity, sprite: SpriteComponent, in parent: SKNode) -> SKSpriteNode {
        if let existing = nodeRegistry[entity] { return existing }
        let node: SKSpriteNode

        switch sprite.content {
        case .solidColor(let colorVal):
            let size = sprite.renderSize.map { CGSize(width: CGFloat($0.x), height: CGFloat($0.y)) }
                       ?? CGSize(width: 1, height: 1)
            node = SKSpriteNode(color: SKColor(
                red: CGFloat(colorVal.x),
                green: CGFloat(colorVal.y),
                blue: CGFloat(colorVal.z),
                alpha: CGFloat(colorVal.w)
            ), size: size)
        case .texture(let name):
            let texture = textureCache[name] ?? SKTexture(imageNamed: name)
            node = SKSpriteNode(texture: texture)
        }
        
        node.name = "entity_\(entity.id)"
        node.zPosition = sprite.layer.rawValue
        node.anchorPoint = CGPoint(x: CGFloat(sprite.anchorPoint.x), y: CGFloat(sprite.anchorPoint.y))
        parent.addChild(node)
        nodeRegistry[entity] = node
        return node
    }
    
    private func updateHealthBar(on parent: SKSpriteNode, ratio: CGFloat) {
        let barWidth: CGFloat = 30
        let barHeight: CGFloat = 4

        var bgNode = parent.childNode(withName: "healthBarBG") as? SKSpriteNode
        
        // Create the health bar if it doesn't exist yet
        if bgNode == nil {
            bgNode = SKSpriteNode(color: SKColor(white: 0.1, alpha: 0.8), size: CGSize(width: barWidth + 2, height: barHeight + 2))
            bgNode?.name = "healthBarBG"
            
            // Position slightly above the entity
            let yOffset = (parent.size.height / 2) + 10
            bgNode?.position = CGPoint(x: 0, y: yOffset)
            bgNode?.zPosition = 10

            let fillNode = SKSpriteNode(color: .red, size: CGSize(width: barWidth, height: barHeight))
            fillNode.name = "healthBarFill"
            fillNode.anchorPoint = CGPoint(x: 0, y: 0.5) // Anchor left so it scales right-to-left
            fillNode.position = CGPoint(x: -barWidth / 2, y: 0)
            fillNode.zPosition = 1

            bgNode?.addChild(fillNode)
            parent.addChild(bgNode!)
        }

        // Counter-flip the health bar so it doesn't render backwards when the enemy faces left
        bgNode?.xScale = parent.xScale < 0 ? -1.0 : 1.0

        // Update the red fill width
        if let fillNode = bgNode?.childNode(withName: "healthBarFill") as? SKSpriteNode {
            fillNode.xScale = max(0, min(1, ratio))
        }
    }
}
