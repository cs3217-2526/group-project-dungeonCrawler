import Foundation
import simd

/// ECS System responsible for detecting when the player transitions between rooms.
///
/// It queries the Global `LevelStateComponent` and the `Player` entity's transform.
/// If the player moves into a neighboring room's bounds, it triggers a transition
/// event via the `LevelOrchestrator`.
public final class LevelTransitionSystem: System {

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
        
        // 2. Manage Cooldown
        if state.transitionCooldown > 0 {
            let newCooldown = max(0, state.transitionCooldown - Float(deltaTime))
            world.modifyComponentIfExist(type: LevelStateComponent.self, for: levelStateEntity) { s in
                s.transitionCooldown = newCooldown
            }
            if newCooldown > 0 { return }
        }

        // 3. Get Player position
        guard let player = world.entities(with: PlayerTagComponent.self).first,
              let transform = world.getComponent(type: TransformComponent.self, for: player)
        else { return }

        let playerPos = transform.position

        // 4. Check against neighboring room bounds in the graph
        guard let graph = state.graph,
              let activeNodeID = state.activeNodeID
        else { return }

        for edge in graph.edges(from: activeNodeID) where !edge.isLocked {
            guard let neighborSpec = graph.specification(for: edge.toNodeID) else { continue }
            
            if neighborSpec.bounds.contains(playerPos) {
                // Trigger the transition event
                orchestrator.transition(to: edge.toNodeID, world: world)
                return
            }
        }
    }
}
