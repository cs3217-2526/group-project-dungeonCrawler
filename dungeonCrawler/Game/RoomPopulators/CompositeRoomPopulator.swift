import Foundation

/// A populator that executes multiple strategies in sequence.
///
/// This allows for complex room population by composing simpler, 
/// specialized strategies (e.g., combining an `EnemyRoomPopulator`
/// with a `LootRoomPopulator`).
public struct CompositeRoomPopulator: RoomPopulatorStrategy {
    private let strategies: [RoomPopulatorStrategy]

    public var requiresCombatEncounter: Bool {
        strategies.contains { $0.requiresCombatEncounter }
    }

    public init(strategies: [RoomPopulatorStrategy]) {
        self.strategies = strategies
    }

    public func populate(context: inout PopulateContext) {
        for strategy in strategies {
            strategy.populate(context: &context)
        }
    }
}
