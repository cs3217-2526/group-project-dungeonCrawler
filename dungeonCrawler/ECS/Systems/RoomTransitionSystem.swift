import Foundation
import simd

/// ECS System responsible for detecting when the player transitions between rooms.
///
/// It queries the Global `LevelStateComponent` and the `Player` entity's transform.
/// If the player moves into a neighboring room's bounds, it triggers appropriate events.
public final class RoomTransitionSystem: System {

    public var dependencies: [System.Type] { [] }

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

        // 2. Process Pending Lockdowns (Distance-based trigger)
        if let pending = state.pendingLockdown {
            processRoomEntryLockdown(pending: pending, playerPos: playerPos, world: world, state: state, levelStateEntity: levelStateEntity)
        }

        // 3. Sensor: Check for neighbor room transitions
        checkNeighborTransitions(playerPos: playerPos, world: world, state: state, levelStateEntity: levelStateEntity, graph: graph)
    }

    private func processRoomEntryLockdown(
        pending: (roomID: UUID, entryPos: SIMD2<Float>),
        playerPos: SIMD2<Float>,
        world: World,
        state: LevelStateComponent,
        levelStateEntity: Entity
    ) {
        guard let spec = state.graph?.specification(for: pending.roomID) else { return }
        
        let dist = simd_distance(playerPos, pending.entryPos)
        let isInside = spec.bounds.contains(playerPos)
        let threshold = WorldConstants.roomEntryInset
        
        if isInside && dist >= threshold {
            orchestrator.lockRoom(pending.roomID, world: world)
            world.modifyComponentIfExist(type: LevelStateComponent.self, for: levelStateEntity) { state in
                state.pendingLockdown = nil
            }
        } else if !isInside {
            // Player left the room before reaching the lockdown distance
            world.modifyComponentIfExist(type: LevelStateComponent.self, for: levelStateEntity) { state in
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

        // Block transitions while the active room is still locked (has enemies).
        if orchestrator.isRoomLocked(activeNodeID, in: world) {
            return
        }

        for edge in graph.edges(from: activeNodeID) {
            guard let neighborSpec = graph.specification(for: edge.toNodeID) else { continue }

            if neighborSpec.bounds.contains(playerPos) {
                // Determine the new active room and update pending lockdown state
                world.modifyComponentIfExist(type: LevelStateComponent.self, for: levelStateEntity) { state in
                    state.activeNodeID = edge.toNodeID
                    state.pendingLockdown = (edge.toNodeID, playerPos)
                }
                return
            }
        }
    }
}
