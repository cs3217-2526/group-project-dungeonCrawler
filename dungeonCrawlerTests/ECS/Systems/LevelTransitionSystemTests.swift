import Testing
import simd
import CoreGraphics
@testable import dungeonCrawler

@Suite("LevelTransitionSystem")
struct LevelTransitionSystemTests {

    // MARK: - Helpers

    private let screenSize = CGSize(width: 400, height: 800)

    /// Two-room linear dungeon — minimal setup for transition tests.
    private func makeOrchestrator() -> LevelOrchestrator {
        LevelOrchestrator(
            layoutStrategy: LinearDungeonLayout(roomCount: 2, enemyPool: [.charger]),
            roomConstructor: BoxRoomConstructor()
        )
    }

    // MARK: - Guard: no level loaded

    @Test func updateWithoutLevelDoesNotCrash() {
        let system = LevelTransitionSystem(orchestrator: makeOrchestrator())
        // No loadLevel call — must not crash
        system.update(deltaTime: 0.016, world: World())
    }

    // MARK: - Transition Detection

    @Test func playerInNeighborRoomTriggersTransition() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = LevelTransitionSystem(orchestrator: orchestrator)
        
        // Get state from world
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        
        let startID = try #require(state.activeNodeID)
        let graph   = try #require(state.graph)

        let edge         = try #require(graph.edges(from: startID).first)
        let neighborDesc = try #require(graph.specification(for: edge.toNodeID))

        // Place player inside the neighbour's bounds
        let player = try #require(world.entities(with: PlayerTagComponent.self).first)
        world.modifyComponentIfExist(type: TransformComponent.self, for: player) { t in
            t.position = neighborDesc.bounds.center
        }

        // deltaTime > cooldown (0.5 s) so the check is not blocked
        system.update(deltaTime: 1.0, world: world)

        // Verify activeNodeID updated in the state component
        let updatedState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState.activeNodeID == edge.toNodeID)
    }

    @Test func playerInCurrentRoomDoesNotTransition() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = LevelTransitionSystem(orchestrator: orchestrator)
        
        // Get state from world
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let startID = try #require(state.activeNodeID)

        // Player stays at start room center — no transition expected
        system.update(deltaTime: 1.0, world: world)

        let updatedState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState.activeNodeID == startID)
    }

    // MARK: - Cooldown

    @Test func cooldownPreventsImmediateRetrigger() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = LevelTransitionSystem(orchestrator: orchestrator)
        
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        
        let startID = try #require(state.activeNodeID)
        let graph   = try #require(state.graph)

        let edge         = try #require(graph.edges(from: startID).first)
        let neighborDesc = try #require(graph.specification(for: edge.toNodeID))
        let neighborID   = edge.toNodeID

        let player = try #require(world.entities(with: PlayerTagComponent.self).first)

        // First transition: move into neighbour
        world.modifyComponentIfExist(type: TransformComponent.self, for: player) { t in
            t.position = neighborDesc.bounds.center
        }
        system.update(deltaTime: 1.0, world: world)
        
        let updatedState1 = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState1.activeNodeID == neighborID)

        // Immediately move back toward start room — cooldown must block retrigger
        let startDesc = try #require(graph.specification(for: startID))
        world.modifyComponentIfExist(type: TransformComponent.self, for: player) { t in
            t.position = startDesc.bounds.center
        }
        system.update(deltaTime: 0.01, world: world)  // still within 0.5 s cooldown

        let updatedState2 = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState2.activeNodeID == neighborID)
    }

    @Test func cooldownExpiresAndAllowsNextTransition() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = LevelTransitionSystem(orchestrator: orchestrator)
        
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        
        let startID = try #require(state.activeNodeID)
        let graph   = try #require(state.graph)

        let edge         = try #require(graph.edges(from: startID).first)
        let neighborDesc = try #require(graph.specification(for: edge.toNodeID))
        let neighborID   = edge.toNodeID

        let player = try #require(world.entities(with: PlayerTagComponent.self).first)

        // First transition
        world.modifyComponentIfExist(type: TransformComponent.self, for: player) { t in
            t.position = neighborDesc.bounds.center
        }
        system.update(deltaTime: 1.0, world: world)
        
        let updatedState1 = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState1.activeNodeID == neighborID)

        // Move back to start room and wait out the cooldown
        let startDesc = try #require(graph.specification(for: startID))
        world.modifyComponentIfExist(type: TransformComponent.self, for: player) { t in
            t.position = startDesc.bounds.center
        }
        system.update(deltaTime: 1.0, world: world)  // cooldown fully expired

        let updatedState2 = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState2.activeNodeID == startID)
    }
}
