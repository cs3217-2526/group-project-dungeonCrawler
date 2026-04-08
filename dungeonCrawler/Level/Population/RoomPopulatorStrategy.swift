import Foundation

// Boundary between game logic and level generation

/// Defines a strategy for populating a room with gameplay entities (enemies, items, etc.).
public protocol RoomPopulatorStrategy {

    /// Whether this room requires a combat encounter (lockdown) when entered.
    var requiresCombatEncounter: Bool { get }

    /// Populates the given world with entities for the specified room.
    func populate(context: inout PopulateContext)
}
