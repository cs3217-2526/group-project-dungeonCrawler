import Foundation
import simd

/// Generates an L-shaped dungeon with a horizontal leg (east) and a vertical
/// leg (south) turning at the far end. The boss room anchors the bottom of the
/// vertical leg.
///
/// Layout:
/// ```
/// [Start]──[combat1]──[corner]
///                         │
///                     [combat2]──[boss]
/// ```
public final class LShapeDungeonLayout: DungeonLayoutStrategy {

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
        let level = context.floorIndex

        let builder = LayoutBuilder(
            startRoom: RoomBounds(origin: SIMD2(-roomWidth / 2, -roomHeight / 2), size: size),
            populator: WeaponRoomPopulator()
        )
        let startID = builder.startNodeID

        // Horizontal leg
        let combat1ID = builder.addRoom(
            extending: startID,
            direction: .east,
            size: size,
            corridor: corridor,
            populator: EnemyRoomPopulator(
                enemyCount: enemyCount(roomIndex: 1, levelNumber: level),
                enemyPool: enemyPool
            )
        )
        let cornerID = builder.addRoom(
            extending: combat1ID,
            direction: .east,
            size: size,
            corridor: corridor,
            populator: EnemyRoomPopulator(
                enemyCount: enemyCount(roomIndex: 2, levelNumber: level),
                enemyPool: enemyPool
            )
        )

        // Vertical leg turning south
        let combat2ID = builder.addRoom(
            extending: cornerID,
            direction: .south,
            size: size,
            corridor: corridor,
            populator: EnemyRoomPopulator(
                enemyCount: enemyCount(roomIndex: 3, levelNumber: level),
                enemyPool: enemyPool
            )
        )

        // Boss room
        builder.addRoom(
            extending: combat2ID,
            direction: .east,
            size: size,
            corridor: corridor,
            isBoss: true,
            populator: EnemyRoomPopulator(
                enemyCount: 3 + level,
                enemyPool: enemyPool
            )
        )

        return builder.build()
    }

    // MARK: - Helpers

    private func enemyCount(roomIndex: Int, levelNumber: Int) -> Int {
        2 + (levelNumber - 1) + (roomIndex / 2)
    }
}
