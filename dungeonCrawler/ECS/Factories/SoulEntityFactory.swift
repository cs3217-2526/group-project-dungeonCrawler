import Foundation
import simd

/// Spawns the soul collectible at the given position.
///
/// Components attached:
///   • TransformComponent        — world position and scale
///   • SpriteComponent           — first soul frame, rendered on the pickUp layer
///   • LoopingAnimationComponent — cycles through all soul frames
///   • SoulComponent             — marks this as the soul collectible
///   • RoomMemberComponent       — ties the entity to the boss room for cleanup
public struct SoulEntityFactory: EntityFactory {
    let position: SIMD2<Float>
    let roomID: UUID
    let animationFrameNames: [String]
    let animationFrameDuration: Double
    let scale: Float

    public init(
        position: SIMD2<Float>,
        roomID: UUID,
        animationFrameNames: [String],
        animationFrameDuration: Double,
        scale: Float = 60.0 / 16.0
    ) {
        self.position               = position
        self.roomID                 = roomID
        self.animationFrameNames    = animationFrameNames
        self.animationFrameDuration = animationFrameDuration
        self.scale                  = scale
    }

    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: scale), to: entity)
        world.addComponent(component: SpriteComponent(
            content: .texture(name: animationFrameNames.first ?? "character_soul_0"),
            layer: .pickUp
        ), to: entity)
        world.addComponent(component: LoopingAnimationComponent(
            frameNames:    animationFrameNames,
            frameDuration: animationFrameDuration
        ), to: entity)
        world.addComponent(component: SoulComponent(), to: entity)
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: entity)
        return entity
    }
}
