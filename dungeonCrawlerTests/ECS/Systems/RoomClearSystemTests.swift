import Testing
import Foundation
import simd
@testable import dungeonCrawler

@Suite("RoomClearSystem")
struct RoomClearSystemTests {

    // MARK: - Helpers

    private func makeOrchestrator() -> LevelOrchestrator {
        LevelOrchestrator(
            layoutStrategy: LinearDungeonLayout(roomCount: 2, enemyPool: []),
            roomConstructor: BoxRoomConstructor()
        )
    }

    private func spawnEnemy(in world: World, roomID: UUID, hp: Float) -> Entity {
        let enemy = world.createEntity()
        world.addComponent(component: HealthComponent(base: hp), to: enemy)
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: enemy)
        world.addComponent(component: EnemyTagComponent(textureName: "enemy", scale: 1.0), to: enemy)
        return enemy
    }

    // MARK: - Logic Tests

    @Test func roomRemainsLockedWithLivingEnemies() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)
        
        let system = RoomClearSystem(orchestrator: orchestrator)
        
        // 1. Setup: Get Middle room
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let startID = try #require(state.activeNodeID)
        let midID = try #require(state.graph?.edges(from: startID).first?.toNodeID)
        let midRoomEntity = try #require(orchestrator.roomEntity(for: midID))
        
        // 2. Mark room as in combat
        world.addComponent(component: RoomInCombatTag(), to: midRoomEntity)
        world.addComponent(component: CombatEncounterTag(), to: midRoomEntity)
        
        // 3. Spawn living enemies
        _ = spawnEnemy(in: world, roomID: midID, hp: 10)
        _ = spawnEnemy(in: world, roomID: midID, hp: 5)
        
        // 4. Update
        system.update(deltaTime: 0.016, world: world)
        
        // 5. Verify: Still in combat
        #expect(world.getComponent(type: RoomInCombatTag.self, for: midRoomEntity) != nil)
        #expect(world.getComponent(type: CombatEncounterTag.self, for: midRoomEntity) != nil)
    }

    @Test func roomUnlocksWhenAllEnemiesAreDefeated() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)
        
        let system = RoomClearSystem(orchestrator: orchestrator)
        
        // 1. Setup: Get Middle room
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let midID = try #require(state.graph?.edges(from: state.activeNodeID!).first?.toNodeID)
        let midRoomEntity = try #require(orchestrator.roomEntity(for: midID))
        
        // 2. Mark room as in combat
        world.addComponent(component: RoomInCombatTag(), to: midRoomEntity)
        world.addComponent(component: CombatEncounterTag(), to: midRoomEntity)
        
        // 3. Spawn dead enemies
        _ = spawnEnemy(in: world, roomID: midID, hp: 0)
        
        // 4. Update
        system.update(deltaTime: 0.016, world: world)
        
        // 5. Verify: Unlocked
        #expect(world.getComponent(type: RoomInCombatTag.self, for: midRoomEntity) == nil)
        #expect(world.getComponent(type: CombatEncounterTag.self, for: midRoomEntity) == nil)
    }

    @Test func barriersAreRemovedOnClear() throws {
        let orchestrator = makeOrchestrator()
        let world = World()
        orchestrator.loadLevel(1, world: world)
        
        let system = RoomClearSystem(orchestrator: orchestrator)
        
        // 1. Setup: Get Middle room
        let stateEntity = try #require(world.entities(with: LevelStateComponent.self).first)
        let state = try #require(world.getComponent(type: LevelStateComponent.self, for: stateEntity))
        let midID = try #require(state.graph?.edges(from: state.activeNodeID!).first?.toNodeID)
        let midRoomEntity = try #require(orchestrator.roomEntity(for: midID))
        
        // 2. Mark room as in combat
        world.addComponent(component: RoomInCombatTag(), to: midRoomEntity)
        
        // 3. Spawn a barrier
        let barrier = world.createEntity()
        world.addComponent(component: BarrierTag(), to: barrier)
        world.addComponent(component: RoomMemberComponent(roomID: midID), to: barrier)
        
        // 4. Spawn dead enemies
        _ = spawnEnemy(in: world, roomID: midID, hp: 0)
        
        // 5. Update
        system.update(deltaTime: 0.016, world: world)
        
        // 6. Verify: Barrier destroyed
        #expect(world.isAlive(entity: barrier) == false)
    }
}
