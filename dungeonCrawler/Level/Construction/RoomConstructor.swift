import Foundation
import simd

/// A fluent builder that abstracts ECS boilerplate for room construction.
///
/// `RoomBuilder` allows constructors to focus purely on geometry by providing
/// semantic methods `addFloor`, `addWall`, and `addObstacle`, which internally
/// handle entity creation and component attachment.
public final class RoomBuilder {
    private let world: World
    public let bounds: RoomBounds
    private let roomID: UUID
    public var renderVisualSprites: Bool

    public init(
        world: World,
        bounds: RoomBounds,
        roomID: UUID,
        renderVisualSprites: Bool = true
    ) {
        self.world = world
        self.bounds = bounds
        self.roomID = roomID
        self.renderVisualSprites = renderVisualSprites
    }

    /// Extrudes the main floor for the room.
    public func addFloor() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: bounds.center), to: entity)
        if renderVisualSprites {
            world.addComponent(component: SpriteComponent.floor(size: bounds.size), to: entity)
        }
        world.addComponent(component: FloorTag(), to: entity)
        world.addComponent(component: OwnerRoomComponent(roomID: roomID), to: entity)
    }

    /// Places a wall collider and sprite at the given position.
    public func addWall(at position: SIMD2<Float>, size: SIMD2<Float>) {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        if renderVisualSprites {
            world.addComponent(component: SpriteComponent.wall(size: size), to: entity)
        }
        world.addComponent(component: WallTag(), to: entity)
        world.addComponent(component: OwnerRoomComponent(roomID: roomID), to: entity)
    }

    /// Places a solid obstacle within the room.
    public func addObstacle(at position: SIMD2<Float>, size: SIMD2<Float>) {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: SpriteComponent.obstacle(size: size), to: entity)
        world.addComponent(component: ObstacleTag(), to: entity)
        world.addComponent(component: OwnerRoomComponent(roomID: roomID), to: entity)
    }
}

/// Defines the physical structure of a single room.
public protocol RoomConstructor {
    /// Constructs the physical room.
    /// - Parameters:
    ///   - builder: The fluent API for placing physical objects into the `World`.
    ///   - specification: Geometric description and rules for the room.
    ///   - doorways: Openings the constructor must leave in its perimeter.
    ///   - generator: The deterministic RNG for procedural choices.
    func construct(
        builder: RoomBuilder,
        specification: RoomSpecification,
        doorways: [Doorway],
        using generator: inout SeededGenerator
    )
}
