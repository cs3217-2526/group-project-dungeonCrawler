import Foundation

/// A strategy for spawning a random set of enemies within a room.
public struct EnemyRoomPopulator: RoomPopulatorStrategy {
    /// Number of enemies to spawn.
    public let enemyCount: Int
    /// Pool of potential enemy types to choose from.
    public var enemyPool: [EnemyType]

    public var requiresCombatEncounter: Bool { enemyCount > 0 && !enemyPool.isEmpty }

    public init(enemyCount: Int, enemyPool: [EnemyType]) {
        self.enemyCount = enemyCount
        self.enemyPool = enemyPool
    }

    public func populate(context: inout PopulateContext) {
        guard enemyCount > 0, !enemyPool.isEmpty else { return }

        for _ in 0..<enemyCount {
            guard let type = enemyPool.randomElement(using: &context.generator),
                  let position = context.findEmptySpace()
            else { continue }
            
            context.spawnEnemy(at: position, type: type)
        }
    }
}
