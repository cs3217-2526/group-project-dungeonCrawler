import Foundation
import CoreGraphics
import simd

/// Generates a dungeon as a straight horizontal chain of rooms.
///
/// Simplest strategy, just place side by side.
///
/// **Enemy pool injection:** `enemyPool` is a constructor parameter rather than
/// a hard-coded array.
public final class LinearDungeonLayout: DungeonLayoutStrategy {
    public let roomCount: Int

    /// Pool of enemy types to pick from when populating combat rooms.
    /// Injected by the caller
    public let enemyPool: [EnemyType]
    public let corridorLength: Float

    public init(roomCount: Int, enemyPool: [EnemyType], corridorLength: Float = 200) {
        self.roomCount     = max(2, roomCount)
        self.enemyPool     = enemyPool.isEmpty ? [.charger] : enemyPool
        self.corridorLength = max(50, corridorLength)
    }

    // MARK: - DungeonLayoutStrategy

    public func generate(context: GenerationContext) -> DungeonGraph {
        _ = context.makeGenerator()

        let roomWidth: Float  = 1000
        let roomHeight: Float = 800
        let size = SIMD2(roomWidth, roomHeight)

        let builder = LayoutBuilder()
        
        // Start Room
        let startID = builder.placeStartRoom(
            bounds: RoomBounds(origin: SIMD2(-roomWidth / 2, -roomHeight / 2), size: size),
            populator: WeaponRoomPopulator()
        )
        
        var currentID = startID
        for index in 1..<roomCount {
            let isBoss = (index == roomCount - 1)
            let count = enemyCountFor(
                roomIndex: index, 
                levelNumber: context.floorIndex, 
                isBoss: isBoss, 
                isStart: false
            )
            
            let populator: RoomPopulatorStrategy = (count > 0)
                ? EnemyRoomPopulator(enemyCount: count, enemyPool: enemyPool)
                : EmptyRoomPopulator()
            
            currentID = builder.addRoom(
                extending: currentID,
                direction: .east,
                size: size,
                corridor: CorridorSpecification(length: corridorLength),
                populator: populator
            )
        }
        
        return builder.build()
    }

    // MARK: - Helpers

    private func enemyCountFor(
        roomIndex: Int,
        levelNumber: Int,
        isBoss: Bool,
        isStart: Bool
    ) -> Int {
        if isStart { return 0 }
        if isBoss  { return 3 + levelNumber }
        return 2 + (levelNumber - 1) + (roomIndex / 2)
    }
}
