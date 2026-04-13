import Foundation

/// Advances one-shot particle effect animations and destroys finished entities.
///
/// Must run before `RenderSystem` so the current frame is applied before rendering.
public final class ParticleEffectSystem: System {

    public var dependencies: [System.Type] { [] }

    private let destructionQueue: DestructionQueue

    public init(destructionQueue: DestructionQueue) {
        self.destructionQueue = destructionQueue
    }

    public func update(deltaTime: Double, world: World) {
        for entity in world.entities(with: ParticleEffectComponent.self) {
            guard let effect = world.getComponent(type: ParticleEffectComponent.self, for: entity),
                  let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
            else { continue }

            if effect.isFinished {
                destructionQueue.enqueue(entity)
                continue
            }

            let previousFrame = effect.frameIndex
            effect.advance(by: deltaTime)

            // Double the entity's scale each time the frame advances
            if effect.frameIndex != previousFrame,
               let transform = world.getComponent(type: TransformComponent.self, for: entity) {
                transform.scale *= 2.0
            }

            if let name = effect.currentFrameName {
                sprite.content = .texture(name: name)
            }
        }

        destructionQueue.flush(world: world)
    }
}
