import Foundation

// Boundary between game logic and level generation

/// Defines a strategy for populating a room with gameplay entities (enemies, items, etc.).
public protocol RoomPopulatorStrategy {

    /// Populates the given world with entities for the specified room.
    /// - Parameters:
    ///   - world: The ECS world to create entities in.
    ///   - bounds: The spatial extent of the room.
    ///   - scale: The canonical entity scale (derived from virtual resolution).
    ///   - roomID: The unique identifier of the room (for OwnerRoomComponent).
    ///   - generator: The deterministic RNG for item/enemy scattering.
    func populate(world: World, bounds: RoomBounds, scale: Float, roomID: UUID, using generator: inout SeededGenerator)
}
