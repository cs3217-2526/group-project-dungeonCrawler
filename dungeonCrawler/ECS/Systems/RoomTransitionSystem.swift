import Foundation
import simd

/// ECS System responsible for detecting when the player transitions between rooms.
///
/// It queries the Global `LevelStateComponent` and the `Player` entity's transform.
/// If the player moves into a neighboring room's bounds, it triggers appropriate events.
public final class RoomTransitionSystem: System {

    public var dependencies: [System.Type] { [MovementSystem.self, CollisionSystem.self] }

    private let orchestrator: LevelOrchestrator

    public init(orchestrator: LevelOrchestrator) {
        self.orchestrator = orchestrator
    }

    public func update(deltaTime: Double, world: World) {
        // 1. Get the Global Level State
        guard let levelStateEntity = world.entities(with: LevelStateComponent.self).first,
              let state = world.getComponent(type: LevelStateComponent.self, for: levelStateEntity),
              let graph = state.graph
        else { return }
        
        guard let player = world.entities(with: PlayerTagComponent.self).first,
              let transform = world.getComponent(type: TransformComponent.self, for: player)
        else { return }

        let playerPos = transform.position

        // 2. Sensor: Check for neighbor room transitions (Must run BEFORE lockdown checks to allow peeks)
        checkNeighborTransitions(playerPos: playerPos, world: world, state: state, levelStateEntity: levelStateEntity, graph: graph)

        // 3. Process Pending Lockdowns (Distance-based trigger)
        // Re-fetch the state from the world AFTER neighbor transitions, in case it was updated.
        if let updatedState = world.getComponent(type: LevelStateComponent.self, for: levelStateEntity),
           let pending = updatedState.pendingLockdown {
            processRoomEntryLockdown(pending: pending, playerPos: playerPos, world: world, levelStateEntity: levelStateEntity, graph: graph)
        }
    }

    private func processRoomEntryLockdown(
        pending: (roomID: UUID, entryPos: SIMD2<Float>),
        playerPos: SIMD2<Float>,
        world: World,
        levelStateEntity: Entity,
        graph: DungeonGraph
    ) {
        guard let spec = graph.specification(for: pending.roomID) else { return }
        
        let dist = simd_distance(playerPos, pending.entryPos)
        let isInside = spec.bounds.contains(playerPos)
        let threshold = WorldConstants.roomEntryInset
        
        if isInside && dist >= threshold {
            orchestrator.lockRoom(pending.roomID, world: world)
            
            // Guarded Clear: Only clear if the pending room is still the one we just locked
            if let state = world.getComponent(type: LevelStateComponent.self, for: levelStateEntity),
               state.pendingLockdown?.roomID == pending.roomID {
                state.pendingLockdown = nil
            }
        } else if !isInside {
            // Player left the room before reaching the lockdown distance.
            // Guarded Clear: Only clear if the pending room is still the one the player just left.
            if let state = world.getComponent(type: LevelStateComponent.self, for: levelStateEntity),
               state.pendingLockdown?.roomID == pending.roomID {
                state.pendingLockdown = nil
            }
        }
    }

    private func checkNeighborTransitions(
        playerPos: SIMD2<Float>,
        world: World,
        state: LevelStateComponent,
        levelStateEntity: Entity,
        graph: DungeonGraph
    ) {
        guard let activeNodeID = state.activeNodeID else { return }

        // Block transitions only if the room requires lockdown AND the lockdown is no longer "pending"
        // (meaning the player has already crossed the 80-unit threshold).
        if orchestrator.requiresLockdown(activeNodeID, in: world) && state.pendingLockdown == nil {
            return
        }

        for edge in graph.edges(from: activeNodeID) {
            guard let neighborSpec = graph.specification(for: edge.toNodeID) else { continue }

            if neighborSpec.bounds.contains(playerPos) {
                // Determine the new active room and update pending lockdown state
                // Only trigger a pending lockdown if the destination room actually requires one
                let shouldLock = orchestrator.requiresLockdown(edge.toNodeID, in: world)

                if let state = world.getComponent(type: LevelStateComponent.self, for: levelStateEntity) {
                    state.activeNodeID = edge.toNodeID
                    state.pendingLockdown = shouldLock ? (edge.toNodeID, playerPos) : nil
                }
                return
            }
        }
    }
}
