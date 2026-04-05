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
              let state = world.getComponent(type: LevelStateComponent.self, for: levelStateEntity)
        else { return }
        
        guard let player = world.entities(with: PlayerTagComponent.self).first,
              let transform = world.getComponent(type: TransformComponent.self, for: player)
        else { return }

        let playerPos = transform.position

        orchestrator.processPendingRoomLockdowns(playerPos: playerPos, world: world)

        guard let graph = state.graph,
              let activeNodeID = state.activeNodeID
        else { return }

        // Block transitions while the active room is still locked (has enemies).
        if orchestrator.isRoomLocked(activeNodeID, in: world) {
            return
        }

        for edge in graph.edges(from: activeNodeID) {
            guard let neighborSpec = graph.specification(for: edge.toNodeID) else { continue }

            if neighborSpec.bounds.contains(playerPos) {
                orchestrator.transition(to: edge.toNodeID, playerPos: playerPos, world: world)
                return
            }
        }
    }
}
