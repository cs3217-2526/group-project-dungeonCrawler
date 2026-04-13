import Foundation
import simd

/// Spawns a one-shot particle effect entity at the given position.
///
/// Components attached:
///   • TransformComponent       — world position and scale
///   • SpriteComponent          — initial frame texture, rendered on the entity layer
///   • ParticleEffectComponent  — drives the frame animation; entity is destroyed when done
///   • RoomMemberComponent      — ties the entity to the room for cleanup
public struct ParticleEffectEntityFactory: EntityFactory {
    let position: SIMD2<Float>
    let frameNames: [String]
    let frameDuration: Double
    let roomID: UUID
    let scale: Float

    public init(
        position: SIMD2<Float>,
        frameNames: [String],
        frameDuration: Double,
        roomID: UUID,
        scale: Float = 60.0 / 16.0
    ) {
        self.position      = position
        self.frameNames    = frameNames
        self.frameDuration = frameDuration
        self.roomID        = roomID
        self.scale         = scale
    }

    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: scale), to: entity)
        world.addComponent(component: SpriteComponent(
            content: .texture(name: frameNames.first ?? ""),
            layer: .entity
        ), to: entity)
        world.addComponent(component: ParticleEffectComponent(
            frameNames:    frameNames,
            frameDuration: frameDuration
        ), to: entity)
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: entity)
        return entity
    }
}
