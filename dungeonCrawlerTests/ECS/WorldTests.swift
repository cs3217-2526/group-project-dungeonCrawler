//
//  WorldTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class WorldTests: XCTestCase {
    
    var world: World!
    var entity1: Entity!
    var entity2: Entity!
    var entity3: Entity!
    var transform1: TransformComponent!
    var transform2: TransformComponent!
    var transform3: TransformComponent!
    var velocity1: VelocityComponent!
    var velocity2: VelocityComponent!
    var input1: InputComponent!

    override func setUp() {
        super.setUp()
        world      = World()
        entity1    = world.createEntity()
        entity2    = world.createEntity()
        entity3    = world.createEntity()
        transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        transform3 = TransformComponent(position: SIMD2<Float>(50, 60))
        velocity1  = VelocityComponent(linear: SIMD2<Float>(1, 2))
        velocity2  = VelocityComponent(linear: SIMD2<Float>(3, 4))
        input1     = InputComponent()
    }

    override func tearDown() {
        world      = nil
        entity1    = nil
        entity2    = nil
        entity3    = nil
        transform1 = nil
        transform2 = nil
        transform3 = nil
        velocity1  = nil
        velocity2  = nil
        input1     = nil
        super.tearDown()
    }
    
    // MARK: - Entity Lifecycle
    
    func testCreateEntity() {
        XCTAssertTrue(world.isAlive(entity: entity1))
    }
    
    func testCreateMultipleEntities() {
        XCTAssertTrue(world.isAlive(entity: entity1))
        XCTAssertTrue(world.isAlive(entity: entity2))
        XCTAssertTrue(world.isAlive(entity: entity3))
        XCTAssertNotEqual(entity1, entity2)
        XCTAssertNotEqual(entity2, entity3)
    }
    
    func testDestroyEntity() {
        XCTAssertTrue(world.isAlive(entity: entity1))

        world.destroyEntity(entity: entity1)
        XCTAssertFalse(world.isAlive(entity: entity1))
    }
    
    func testDestroyEntityRemovesComponents() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: velocity1, to: entity1)

        world.destroyEntity(entity: entity1)

        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity1))
        XCTAssertNil(world.getComponent(type: VelocityComponent.self, for: entity1))
    }
    
    func testDestroyAllEntities() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: transform2, to: entity2)
        world.addComponent(component: transform3, to: entity3)

        world.destroyAllEntities()

        XCTAssertFalse(world.isAlive(entity: entity1))
        XCTAssertFalse(world.isAlive(entity: entity2))
        XCTAssertFalse(world.isAlive(entity: entity3))
        XCTAssertEqual(world.allEntities.count, 0)
        XCTAssertEqual(world.entities(with: TransformComponent.self).count, 0)
    }
    
    func testAllEntities() {
        XCTAssertEqual(world.allEntities.count, 3)
        XCTAssertTrue(world.allEntities.contains(entity1))
        XCTAssertTrue(world.allEntities.contains(entity2))
        XCTAssertTrue(world.allEntities.contains(entity3))

        world.destroyEntity(entity: entity1)

        XCTAssertEqual(world.allEntities.count, 2)
        XCTAssertFalse(world.allEntities.contains(entity1))
        XCTAssertTrue(world.allEntities.contains(entity2))
        XCTAssertTrue(world.allEntities.contains(entity3))
    }
    
    // MARK: - Component Operations
    
    func testAddComponent() {
        world.addComponent(component: transform1, to: entity1)

        let retrieved = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
    }
    
    func testGetComponent() {
        world.addComponent(component: transform1, to: entity1)

        let retrieved = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertEqual(retrieved?.position.x, 10)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testGetNonexistentComponent() {
        let retrieved = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertNil(retrieved)
    }
    
    func testRemoveComponent() {
        world.addComponent(component: transform1, to: entity1)
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity1))

        world.removeComponent(type: TransformComponent.self, from: entity1)
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity1))
    }
    
    // MARK: - Single Component Queries
    
    func testEntitiesWithComponent() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: transform2, to: entity2)
        world.addComponent(component: velocity1,  to: entity3)

        let entities = world.entities(with: TransformComponent.self)
        XCTAssertEqual(entities.count, 2)
        XCTAssertTrue(entities.contains(entity1))
        XCTAssertTrue(entities.contains(entity2))
        XCTAssertFalse(entities.contains(entity3))
    }
    
    func testEntitiesWithComponentEmpty() {
        let entities = world.entities(with: TransformComponent.self)
        XCTAssertEqual(entities.count, 0)
    }
    
    // MARK: - Binary Join Queries
    
    func testEntitiesWithTwoComponents() {
        // entity1: Transform + Velocity
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: velocity1,  to: entity1)

        // entity2: Transform only
        world.addComponent(component: transform2, to: entity2)

        // entity3: Transform + Velocity
        world.addComponent(component: transform3, to: entity3)
        world.addComponent(component: velocity2,  to: entity3)

        let results = world.entities(with: TransformComponent.self, and: VelocityComponent.self)

        XCTAssertEqual(results.count, 2)

        let entities = results.map { $0.entity }
        XCTAssertTrue(entities.contains(entity1))
        XCTAssertFalse(entities.contains(entity2))
        XCTAssertTrue(entities.contains(entity3))

        // Verify component data is returned
        for (entity, transform, velocity) in results {
            if entity == entity1 {
                XCTAssertEqual(transform.position.x, 10)
                XCTAssertEqual(velocity.linear.x, 1)
            } else if entity == entity3 {
                XCTAssertEqual(transform.position.x, 50)
                XCTAssertEqual(velocity.linear.x, 3)
            }
        }
    }
    
    func testBinaryJoinEmpty() {
        let results = world.entities(with: TransformComponent.self, and: VelocityComponent.self)
        XCTAssertEqual(results.count, 0)
    }
    
    func testBinaryJoinNoOverlap() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: velocity1,  to: entity2)

        let results = world.entities(with: TransformComponent.self, and: VelocityComponent.self)
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteEntityLifecycle() {
        XCTAssertTrue(world.isAlive(entity: entity1))

        // Add components
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: velocity1,  to: entity1)
        world.addComponent(component: input1,     to: entity1)

        // Verify components exist
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity1))
        XCTAssertNotNil(world.getComponent(type: VelocityComponent.self, for: entity1))
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: entity1))

        // Modify components
        world.getComponent(type: TransformComponent.self, for: entity1)?.position = SIMD2<Float>(100, 200)

        let transform = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertEqual(transform?.position.x, 100)

        // Remove one component
        world.removeComponent(type: InputComponent.self, from: entity1)
        XCTAssertNil(world.getComponent(type: InputComponent.self, for: entity1))
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity1))

        // Destroy entity
        world.destroyEntity(entity: entity1)
        XCTAssertFalse(world.isAlive(entity: entity1))
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity1))
        XCTAssertNil(world.getComponent(type: VelocityComponent.self, for: entity1))
    }
    
    func testMultipleEntitiesWithDifferentArchetypes() {
        // Archetype 1: Player (Transform + Velocity + Input)
        world.addComponent(component: transform1,         to: entity1)
        world.addComponent(component: velocity1,          to: entity1)
        world.addComponent(component: input1,             to: entity1)
        world.addComponent(component: PlayerTagComponent(), to: entity1)

        // Archetype 2: Enemy (Transform + Velocity)
        world.addComponent(component: transform2, to: entity2)
        world.addComponent(component: velocity2,  to: entity2)

        // Archetype 3: Static prop (Transform only)
        world.addComponent(component: transform3, to: entity3)

        // Query for all movable entities (Transform + Velocity)
        let movable = world.entities(with: TransformComponent.self, and: VelocityComponent.self)
        XCTAssertEqual(movable.count, 2)

        // Query for player
        let players = world.entities(with: PlayerTagComponent.self)
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players.first, entity1)
    }
}
