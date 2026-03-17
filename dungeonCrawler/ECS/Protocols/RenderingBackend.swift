import Foundation

/// Engine-agnostic interface used by RenderSystem to sync entity state to a visual layer.
public protocol RenderingBackend: AnyObject {
    func syncNode(
        for entity: Entity,
        transform: TransformComponent,
        sprite: SpriteComponent,
        velocity: VelocityComponent?
    )
    func removeNode(for entity: Entity)
}
