import Foundation
import simd

/// API for constructing dungeon topologies, so less hardcoding in each
/// layout strategy.
public final class LayoutBuilder {
    private var graph: DungeonGraph?

    public init() {}

    @discardableResult
    public func placeStartRoom(
        bounds: RoomBounds,
        populator: RoomPopulatorStrategy = EmptyRoomPopulator()
    ) -> UUID {
        let spec = RoomSpecification(
            id: UUID(),
            bounds: bounds,
            isStartRoom: true,
            populator: populator
        )
        self.graph = DungeonGraph(startingRoomSpecification: spec)
        return spec.id
    }

    /// Appends a new room to an existing one in a specific direction.
    @discardableResult
    public func addRoom(
        extending fromID: UUID,
        direction: Direction,
        size: SIMD2<Float>,
        corridor: CorridorSpecification = .init(length: 100),
        populator: RoomPopulatorStrategy = EmptyRoomPopulator()
    ) -> UUID {
        guard let fromSpec = graph?.specification(for: fromID) else {
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
            populator: populator
        )

        graph?.addRoom(nextSpec)
        graph?.addBidirectionalConnection(
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
        guard let graph = self.graph else {
            fatalError("LayoutBuilder: build() called before placeStartRoom()")
        }
        return graph
    }
}
