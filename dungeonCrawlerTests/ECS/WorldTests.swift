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
    
    override func setUp() {
        super.setUp()
        world = World()
    }
    
    override func tearDown() {
        world = nil
        super.tearDown()
    }
    
    // MARK: - Entity Lifecycle
    
    func testCreateEntity() {
        let entity = world.createEntity()
        XCTAssertTrue(world.isAlive(entity: entity))
    }
    
    func testCreateMultipleEntities() {
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        let entity3 = world.createEntity()
        
        XCTAssertTrue(world.isAlive(entity: entity1))
        XCTAssertTrue(world.isAlive(entity: entity2))
        XCTAssertTrue(world.isAlive(entity: entity3))
        XCTAssertNotEqual(entity1, entity2)
        XCTAssertNotEqual(entity2, entity3)
    }
    
    func testDestroyEntity() {
        let entity = world.createEntity()
        XCTAssertTrue(world.isAlive(entity: entity))
        
        world.destroyEntity(entity: entity)
        XCTAssertFalse(world.isAlive(entity: entity))
    }
    
    func testDestroyEntityRemovesComponents() {
        let entity = world.createEntity()
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        let velocity = VelocityComponent(linear: SIMD2<Float>(5, 5))
        
        world.addComponent(component: transform, to: entity)
        world.addComponent(component: velocity, to: entity)
        
        world.destroyEntity(entity: entity)
        
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity))
        XCTAssertNil(world.getComponent(type: VelocityComponent.self, for: entity))
    }
    
    func testDestroyAllEntities() {
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        let entity3 = world.createEntity()
        
        world.addComponent(component: TransformComponent(), to: entity1)
        world.addComponent(component: TransformComponent(), to: entity2)
        world.addComponent(component: TransformComponent(), to: entity3)
        
        world.destroyAllEntities()
        
        XCTAssertFalse(world.isAlive(entity: entity1))
        XCTAssertFalse(world.isAlive(entity: entity2))
        XCTAssertFalse(world.isAlive(entity: entity3))
        XCTAssertEqual(world.allEntities.count, 0)
        XCTAssertEqual(world.entities(with: TransformComponent.self).count, 0)
    }
    
    func testAllEntities() {
        XCTAssertEqual(world.allEntities.count, 0)
        
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        
        XCTAssertEqual(world.allEntities.count, 2)
        XCTAssertTrue(world.allEntities.contains(entity1))
        XCTAssertTrue(world.allEntities.contains(entity2))
        
        world.destroyEntity(entity: entity1)
        
        XCTAssertEqual(world.allEntities.count, 1)
        XCTAssertFalse(world.allEntities.contains(entity1))
        XCTAssertTrue(world.allEntities.contains(entity2))
    }
    
    // MARK: - Component Operations
    
    func testAddComponent() {
        let entity = world.createEntity()
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        
        world.addComponent(component: transform, to: entity)
        
        let retrieved = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
    }
    
    func testGetComponent() {
        let entity = world.createEntity()
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        
        world.addComponent(component: transform, to: entity)
        
        let retrieved = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(retrieved?.position.x, 10)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testGetNonexistentComponent() {
        let entity = world.createEntity()
        let retrieved = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNil(retrieved)
    }
    
    func testModifyComponent() {
        let entity = world.createEntity()
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        
        world.addComponent(component: transform, to: entity)
        
        world.modifyComponentIfExist(type: TransformComponent.self, for: entity) { component in
            component.position.x = 100
            component.scale = 2.0
        }
        
        let retrieved = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(retrieved?.position.x, 100)
        XCTAssertEqual(retrieved?.position.y, 20)
        XCTAssertEqual(retrieved?.scale, 2.0)
    }
    
    func testRemoveComponent() {
        let entity = world.createEntity()
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        
        world.addComponent(component: transform, to: entity)
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
        
        world.removeComponent(type: TransformComponent.self, from: entity)
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity))
    }
    
    // MARK: - Single Component Queries
    
    func testEntitiesWithComponent() {
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        let entity3 = world.createEntity()
        
        world.addComponent(component: TransformComponent(), to: entity1)
        world.addComponent(component: TransformComponent(), to: entity2)
        world.addComponent(component: VelocityComponent(), to: entity3)
        
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
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        let entity3 = world.createEntity()
        
        // entity1: Transform + Velocity
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(10, 20)), to: entity1)
        world.addComponent(component: VelocityComponent(linear: SIMD2<Float>(1, 2)), to: entity1)
        
        // entity2: Transform only
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(30, 40)), to: entity2)
        
        // entity3: Transform + Velocity
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(50, 60)), to: entity3)
        world.addComponent(component: VelocityComponent(linear: SIMD2<Float>(3, 4)), to: entity3)
        
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
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        
        world.addComponent(component: TransformComponent(), to: entity1)
        world.addComponent(component: VelocityComponent(), to: entity2)
        
        let results = world.entities(with: TransformComponent.self, and: VelocityComponent.self)
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteEntityLifecycle() {
        // Create entity
        let entity = world.createEntity()
        XCTAssertTrue(world.isAlive(entity: entity))
        
        // Add components
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(10, 20)), to: entity)
        world.addComponent(component: VelocityComponent(linear: SIMD2<Float>(5, 5)), to: entity)
        world.addComponent(component: InputComponent(), to: entity)
        
        // Verify components exist
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: VelocityComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: entity))
        
        // Modify components
        world.modifyComponentIfExist(type: TransformComponent.self, for: entity) { transform in
            transform.position = SIMD2<Float>(100, 200)
        }
        
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform?.position.x, 100)
        
        // Remove one component
        world.removeComponent(type: InputComponent.self, from: entity)
        XCTAssertNil(world.getComponent(type: InputComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
        
        // Destroy entity
        world.destroyEntity(entity: entity)
        XCTAssertFalse(world.isAlive(entity: entity))
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity))
        XCTAssertNil(world.getComponent(type: VelocityComponent.self, for: entity))
    }
    
    func testMultipleEntitiesWithDifferentArchetypes() {
        // Archetype 1: Player (Transform + Velocity + Input)
        let player = world.createEntity()
        world.addComponent(component: TransformComponent(), to: player)
        world.addComponent(component: VelocityComponent(), to: player)
        world.addComponent(component: InputComponent(), to: player)
        world.addComponent(component: PlayerTagComponent(), to: player)
        
        // Archetype 2: Enemy (Transform + Velocity)
        let enemy = world.createEntity()
        world.addComponent(component: TransformComponent(), to: enemy)
        world.addComponent(component: VelocityComponent(), to: enemy)
        
        // Archetype 3: Static prop (Transform only)
        let prop = world.createEntity()
        world.addComponent(component: TransformComponent(), to: prop)
        
        // Query for all movable entities (Transform + Velocity)
        let movable = world.entities(with: TransformComponent.self, and: VelocityComponent.self)
        XCTAssertEqual(movable.count, 2)
        
        // Query for player
        let players = world.entities(with: PlayerTagComponent.self)
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players.first, player)
    }
}
