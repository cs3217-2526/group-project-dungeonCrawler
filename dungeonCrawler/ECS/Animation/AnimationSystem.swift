import Foundation
import simd

/// Drives frame animation for all entities that have an `AnimationComponent`.
///
/// Each tick the system maps velocity to `AnimationDirection` to animation key, advances the
/// frame timer, and writes the resulting texture name into `SpriteComponent.content`.
/// `FacingComponent` is pinned to `.right` so the rendering adapter does not mirror
/// directional sprites (left/right facing is already in the texture frames itself).
public final class AnimationSystem: System {

    public var dependencies: [System.Type] { [MovementSystem.self] }

    public init() {}

    public func update(deltaTime: Double, world: World) {
        for entity in world.entities(with: AnimationComponent.self) {
            guard
                let anim   = world.getComponent(type: AnimationComponent.self, for: entity),
                let sprite = world.getComponent(type: SpriteComponent.self,    for: entity),
                let vel    = world.getComponent(type: VelocityComponent.self,  for: entity)
            else { continue }

            // Derive the desired animation key from velocity, keeping the last direction when idle.
            let direction  = AnimationDirection.from(velocity: vel.linear) ?? anim.lastDirection
            let isMoving   = AnimationDirection.from(velocity: vel.linear) != nil
            let key        = "\(isMoving ? "walk" : "idle")\(direction.rawValue)"

            // Store direction so idle animations face where the character last moved.
            if isMoving { anim.lastDirection = direction }

            // Reset frame index when the animation changes.
            if key != anim.currentAnimation {
                anim.currentAnimation = key
                anim.frameIndex       = 0
                anim.elapsed          = 0
            }

            guard let frames = anim.animations[key], !frames.isEmpty else { continue }

            // Advance the frame timer.
            anim.elapsed += deltaTime
            if anim.elapsed >= anim.frameDuration {
                anim.elapsed   -= anim.frameDuration
                anim.frameIndex = (anim.frameIndex + 1) % frames.count
            }

            sprite.content = .texture(name: frames[anim.frameIndex])

            // Pin facing to .right so the rendering adapter never mirrors directional sprites.
            world.getComponent(type: FacingComponent.self, for: entity)?.facing = .right
        }
    }
}
