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
        // Find all rooms currently in combat
        for roomEntity in world.entities(with: RoomInCombatTag.self) {
            guard let roomMember = world.getComponent(type: RoomMemberComponent.self, for: roomEntity) else { continue }
            let roomID = roomMember.roomID
            
            // Check if any enemies remain in this room
            // We consider an "enemy" any entity with HealthComponent that is NOT the player.
            let hasLivingEnemy = world.entities(with: HealthComponent.self).contains { entity in
                // 1. Must be in this specific room
                guard let member = world.getComponent(type: RoomMemberComponent.self, for: entity),
                      member.roomID == roomID 
                else { return false }
                
                // 2. Must NOT be the player
                guard world.getComponent(type: PlayerTagComponent.self, for: entity) == nil else { return false }
                
                // 3. Must be currently alive (not just enqueued for destruction)
                guard let health = world.getComponent(type: HealthComponent.self, for: entity) else { return false }
                return health.value.current > 0
            }
            
            if !hasLivingEnemy {
                orchestrator.unlockRoom(roomID, world: world)
            }
        }
    }
}
