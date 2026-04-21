import Foundation
import simd

/// Generates a dungeon with a central hub room and four combat rooms branching
/// outward in each cardinal direction. The west room is always the boss room.
///
/// Layout:
/// ```
///       [N combat]
///            |
/// [W boss]--[Start]--[E combat]
///            |
///       [S combat]
/// ```
public final class StarDungeonLayout: DungeonLayoutStrategy {

    public let enemyPool: [EnemyType]
    public let corridorLength: Float

    public init(enemyPool: [EnemyType], corridorLength: Float = 300) {
        self.enemyPool = enemyPool
        self.corridorLength = max(50, corridorLength)
    }

    // MARK: - DungeonLayoutStrategy

    public func generate(context: GenerationContext) -> DungeonGraph {
        let roomWidth:  Float = 1000
        let roomHeight: Float = 800
        let size = SIMD2(roomWidth, roomHeight)
        let corridor = CorridorSpecification(length: corridorLength)

        let builder = LayoutBuilder(
            startRoom: RoomBounds(origin: SIMD2(-roomWidth / 2, -roomHeight / 2), size: size),
            populator: WeaponRoomPopulator()
        )
        let startID = builder.startNodeID

        // Three regular combat rooms on N, E, S branches
        let combatBranches: [(Direction, Int)] = [(.north, 1), (.east, 2), (.south, 3)]
        for (direction, index) in combatBranches {
            let count = enemyCount(roomIndex: index, levelNumber: context.floorIndex, isBoss: false)
            builder.addRoom(
                extending: startID,
                direction: direction,
                size: size,
                corridor: corridor,
                populator: EnemyRoomPopulator(enemyCount: count, enemyPool: enemyPool)
            )
        }

        // West branch: boss room
        builder.addRoom(
            extending: startID,
            direction: .west,
            size: size,
            corridor: corridor,
            isBoss: true,
            populator: EnemyRoomPopulator(
                enemyCount: enemyCount(roomIndex: 4, levelNumber: context.floorIndex, isBoss: true),
                enemyPool: enemyPool
            )
        )

        return builder.build()
    }

    // MARK: - Helpers

    private func enemyCount(roomIndex: Int, levelNumber: Int, isBoss: Bool) -> Int {
        if isBoss { return 3 + levelNumber }
        return 2 + (levelNumber - 1) + (roomIndex / 2)
    }
}
