import Foundation

/// Detects when all living enemies in a combat room have been defeated and unlocks the room.
///
/// Runs after `HealthSystem` so that enemies with 0 HP (queued for destruction but not yet
/// removed) are excluded via the `health.value.current > 0` guard.
public final class RoomClearSystem: System {

    public var dependencies: [System.Type] { [HealthSystem.self] }

    private let orchestrator: LevelOrchestrator

    public init(orchestrator: LevelOrchestrator) {
        self.orchestrator = orchestrator
    }

    public func update(deltaTime: Double, world: World) {
        // 1. Gather the Room IDs of all living entities that have an EnemyTagComponent.
        // This is a single pass O(enemiesWithHealth + healthEntities).
        let livingEnemies = world.entities(with: HealthComponent.self, and: RoomMemberComponent.self, and: EnemyTagComponent.self)
        
        let roomsWithEnemies = Set(livingEnemies.compactMap { (entity, health, member, tag) -> UUID? in
            return health.value.current > 0 ? member.roomID : nil
        })

        // 2. Process all rooms that are currently marked "In Combat"
        for roomEntity in world.entities(with: RoomInCombatTag.self) {
            guard let roomMember = world.getComponent(type: RoomMemberComponent.self, for: roomEntity) else { continue }
            let roomID = roomMember.roomID
            
            // 3. If a combat room's ID is not in the "living enemies" set, it's clear!
            if !roomsWithEnemies.contains(roomID) {
                orchestrator.unlockRoom(roomID, world: world)
            }
        }
    }
}
