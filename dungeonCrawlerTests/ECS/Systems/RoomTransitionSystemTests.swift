import Testing
import simd
import CoreGraphics
@testable import dungeonCrawler

@Suite("RoomTransitionSystem")
struct RoomTransitionSystemTests {

    // MARK: - Helpers

    private func makeOrchestrator() -> LevelOrchestrator {
        LevelOrchestrator(
            layoutStrategy: LinearDungeonLayout(roomCount: 2, enemyPool: [.charger]),
            roomConstructor: BoxRoomConstructor()
        )
    }

    // MARK: - Guard: no level loaded

    @Test func updateWithoutLevelDoesNotCrash() {
        let system = RoomTransitionSystem(orchestrator: makeOrchestrator())
        // No loadLevel call — must not crash
        system.update(deltaTime: 0.016, world: World())
    }

    // MARK: - Transition Detection

    @Test func playerInNeighborRoomTriggersTransition() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = RoomTransitionSystem(orchestrator: orchestrator)

        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))

        let startID = try #require(state.activeNodeID)
        let graph   = try #require(state.graph)

        let edge         = try #require(graph.edges(from: startID).first)
        let neighborDesc = try #require(graph.specification(for: edge.toNodeID))

        // Place player inside the neighbour's bounds
        let player = try #require(world.entities(with: PlayerTagComponent.self).first)
        world.getComponent(type: TransformComponent.self, for: player)?.position = neighborDesc.bounds.center

        system.update(deltaTime: 0.016, world: world)

        // Verify activeNodeID updated and pendingLockdown is set
        let updatedState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(updatedState.activeNodeID == edge.toNodeID)
        #expect(updatedState.pendingLockdown?.roomID == edge.toNodeID)
    }

    // MARK: - Lockdown Distance Logic

    @Test func lockdownTriggersAfterMovingDistance() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = RoomTransitionSystem(orchestrator: orchestrator)
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let startState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let startID = try #require(startState.activeNodeID)
        let edge = try #require(startState.graph?.edges(from: startID).first)
        let neighborID = edge.toNodeID
        let neighborSpec = try #require(startState.graph?.specification(for: neighborID))

        let player = try #require(world.entities(with: PlayerTagComponent.self).first)

        // 1. Enter the room (just inside boundary)
        let entryPoint = neighborSpec.bounds.origin + SIMD2<Float>(5, 5) // Just inside
        world.getComponent(type: TransformComponent.self, for: player)?.position = entryPoint

        system.update(deltaTime: 0.016, world: world)

        // Verify pending state is set
        let stateAfterEntry = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(stateAfterEntry.pendingLockdown != nil)
        #expect(stateAfterEntry.pendingLockdown?.roomID == neighborID)

        // 2. Move 40 units (not enough for 80 unit threshold)
        world.getComponent(type: TransformComponent.self, for: player)?.position = entryPoint + SIMD2<Float>(40, 0)
        system.update(deltaTime: 0.016, world: world)

        let stateAfter40 = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(stateAfter40.pendingLockdown != nil)

        // 3. Move 90 units (past 80 unit threshold)
        world.getComponent(type: TransformComponent.self, for: player)?.position = entryPoint + SIMD2<Float>(90, 0)
        system.update(deltaTime: 0.016, world: world)

        // Verify lockdown triggered (pending state cleared, and room should be locked)
        let finalState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(finalState.pendingLockdown == nil)

        // Check if room requires lockdown in Orchestrator
        #expect(orchestrator.requiresLockdown(neighborID, in: world) == true)
    }

    @Test func peekReleaseClearsPendingState() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = RoomTransitionSystem(orchestrator: orchestrator)
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let startState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let startID = try #require(startState.activeNodeID)
        let edge = try #require(startState.graph?.edges(from: startID).first)
        let neighborID = edge.toNodeID
        let neighborSpec = try #require(startState.graph?.specification(for: neighborID))
        let startSpec = try #require(startState.graph?.specification(for: startID))

        let player = try #require(world.entities(with: PlayerTagComponent.self).first)

        // 1. Enter neighbor
        world.getComponent(type: TransformComponent.self, for: player)?.position = neighborSpec.bounds.center
        system.update(deltaTime: 0.016, world: world)

        let stateAfterEntry = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(stateAfterEntry.activeNodeID == neighborID)
        #expect(stateAfterEntry.pendingLockdown != nil)

        // 2. Immediately step back into starting room (the "peek")
        world.getComponent(type: TransformComponent.self, for: player)?.position = startSpec.bounds.center
        system.update(deltaTime: 0.016, world: world)

        // Since we left the neighbor room's bounds, pendingLockdown should clear
        // AND we should transition back to startID
        let stateAfterPeek = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(stateAfterPeek.activeNodeID == startID)
        #expect(stateAfterPeek.pendingLockdown == nil)
    }

    @Test func emptyRoomDoesNotTriggerLockdown() throws {
        let world = World()
        // Create a layout with an empty room at the end
        let orchestrator = LevelOrchestrator(
            layoutStrategy: LinearDungeonLayout(roomCount: 2, enemyPool: []),
            roomConstructor: BoxRoomConstructor()
        )
        orchestrator.loadLevel(1, world: world)

        let system = RoomTransitionSystem(orchestrator: orchestrator)
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let startState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let startID = try #require(startState.activeNodeID)
        let edge = try #require(startState.graph?.edges(from: startID).first)
        let neighborID = edge.toNodeID
        let neighborSpec = try #require(startState.graph?.specification(for: neighborID))

        let player = try #require(world.entities(with: PlayerTagComponent.self).first)

        // Enter the empty neighbor room
        world.getComponent(type: TransformComponent.self, for: player)?.position = neighborSpec.bounds.center

        system.update(deltaTime: 0.016, world: world)

        // Verify activeNodeID updated but pendingLockdown is NOT set
        let finalState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(finalState.activeNodeID == neighborID)
        #expect(finalState.pendingLockdown == nil)

        // Verify orchestrator confirms no lockdown required
        #expect(orchestrator.requiresLockdown(neighborID, in: world) == false)
    }

    @Test func transitionBetweenCombatRoomsPreservesNewPendingState() throws {
        let orchestrator = LevelOrchestrator(
            layoutStrategy: LinearDungeonLayout(roomCount: 3, enemyPool: [.charger]),
            roomConstructor: BoxRoomConstructor()
        )
        let world = World()
        orchestrator.loadLevel(1, world: world)

        let system = RoomTransitionSystem(orchestrator: orchestrator)
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let player = try #require(world.entities(with: PlayerTagComponent.self).first)

        // 1. Setup: Get Middle and End rooms (both combat)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let graph = try #require(state.graph)
        let startID = try #require(state.activeNodeID)
        
        let midID = try #require(graph.edges(from: startID).first?.toNodeID)
        let endID = try #require(graph.edges(from: midID).first { $0.toNodeID != startID }?.toNodeID)
        
        let endSpec = try #require(graph.specification(for: endID))

        // 2. Simulate State: Active = Mid, Pending = Mid (player just crossed boundary into Mid)
        if let s = world.getComponent(type: LevelStateComponent.self, for: stateEntity) {
            s.activeNodeID = midID
            s.pendingLockdown = (midID, SIMD2<Float>(100, 100))
        }

        // 3. Move player into End room
        world.getComponent(type: TransformComponent.self, for: player)?.position = endSpec.bounds.center

        // 4. Update
        system.update(deltaTime: 0.016, world: world)

        // 5. Verify:
        // - Active ID should be End
        // - Pending Lockdown should be End (and NOT nil, which was the bug!)
        let finalState = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        #expect(finalState.activeNodeID == endID)
        #expect(finalState.pendingLockdown?.roomID == endID)
    }
}
