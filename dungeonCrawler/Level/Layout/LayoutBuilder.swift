import Foundation
import simd

/// API for constructing dungeon topologies, so less hardcoding in each
/// layout strategy.
public final class LayoutBuilder {
    private var graph: DungeonGraph
    public let startNodeID: UUID

    public init(
        startRoom bounds: RoomBounds,
        populator: RoomPopulatorStrategy = EmptyRoomPopulator()
    ) {
        let id = UUID()
        let spec = RoomSpecification(
            id: id,
            bounds: bounds,
            isStartRoom: true,
            populator: populator
        )
        self.graph = DungeonGraph(startingRoomSpecification: spec)
        self.startNodeID = id
    }

    /// Appends a new room to an existing one in a specific direction.
    @discardableResult
    public func addRoom(
        extending fromID: UUID,
        direction: Direction,
        size: SIMD2<Float>,
        corridor: CorridorSpecification = .init(length: 100),
        isBoss: Bool = false,
        populator: RoomPopulatorStrategy = EmptyRoomPopulator()
    ) -> UUID {
        guard let fromSpec = graph.specification(for: fromID) else {
            fatalError("LayoutBuilder: Cannot extend from non-existent room \(fromID)")
        }

        let nextBounds = fromSpec.bounds.adjacentBounds(
            direction: direction,
            spacing: corridor.length,
            size: size
        )

        let nextID = UUID()
        let nextSpec = RoomSpecification(
            id: nextID,
            bounds: nextBounds,
            isStartRoom: false,
            isBoss: isBoss,
            populator: populator
        )

        graph.addRoom(nextSpec)
        graph.addBidirectionalConnection(
            from: fromID,
            to: nextID,
            exitDirection: direction,
            entryDirection: direction.opposite,
            corridor: corridor
        )

        return nextID
    }

    /// Returns the fully constructed graph.
    public func build() -> DungeonGraph {
        return graph
    }
}
