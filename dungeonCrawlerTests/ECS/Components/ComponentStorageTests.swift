//
//  ComponentStorageTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler
 
final class ComponentStorageTests: XCTestCase {
    
    var storage: ComponentStorage!
    var entity1: Entity!
    var entity2: Entity!
    
    override func setUp() {
        super.setUp()
        storage = ComponentStorage()
        entity1 = Entity()
        entity2 = Entity()
    }
    
    override func tearDown() {
        storage = nil
        entity1 = nil
        entity2 = nil
        super.tearDown()
    }
    
    // MARK: - Add & Get
    
    func testAddAndGetComponent() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        storage.add(component: transform, to: entity1)
        
        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testAddMultipleComponentTypes() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        let velocity = VelocityComponent(linear: SIMD2<Float>(5, 5))
        let input = InputComponent()
        
        storage.add(component: transform, to: entity1)
        storage.add(component: velocity, to: entity1)
        storage.add(component: input, to: entity1)
        
        XCTAssertNotNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNotNil(storage.get(type: VelocityComponent.self, for: entity1))
        XCTAssertNotNil(storage.get(type: InputComponent.self, for: entity1))
    }
    
    func testGetNonexistentComponent() {
        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertNil(retrieved)
    }
    
    func testAddSameComponentToDifferentEntities() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        storage.add(component: transform1, to: entity1)
        storage.add(component: transform2, to: entity2)
        
        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity1)?.position.x, 10)
        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity2)?.position.x, 30)
    }
    
    // MARK: - Modify
    
    func testModifyComponent() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        storage.add(component: transform, to: entity1)
        
        storage.modify(type: TransformComponent.self, for: entity1) { component in
            component.position.x = 100
        }
        
        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertEqual(retrieved?.position.x, 100)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testModifyNonexistentComponent() {
        // Should not crash
        storage.modify(type: TransformComponent.self, for: entity1) { component in
            component.position.x = 100
        }
        
        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
    }
    
    // MARK: - Remove
    
    func testRemoveSpecificComponent() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        let velocity = VelocityComponent(linear: SIMD2<Float>(5, 5))
        
        storage.add(component: transform, to: entity1)
        storage.add(component: velocity, to: entity1)
        
        storage.remove(type: TransformComponent.self, from: entity1)
        
        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNotNil(storage.get(type: VelocityComponent.self, for: entity1))
    }
    
    func testRemoveAllComponents() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        let velocity = VelocityComponent(linear: SIMD2<Float>(5, 5))
        let input = InputComponent()
        
        storage.add(component: transform, to: entity1)
        storage.add(component: velocity, to: entity1)
        storage.add(component: input, to: entity1)
        
        storage.removeAll(from: entity1)
        
        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNil(storage.get(type: VelocityComponent.self, for: entity1))
        XCTAssertNil(storage.get(type: InputComponent.self, for: entity1))
    }
    
    func testRemoveAllDoesNotAffectOtherEntities() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        storage.add(component: transform1, to: entity1)
        storage.add(component: transform2, to: entity2)
        
        storage.removeAll(from: entity1)
        
        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNotNil(storage.get(type: TransformComponent.self, for: entity2))
    }
    
    // MARK: - Entities Query
    
    func testEntitiesWithComponent() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        storage.add(component: transform1, to: entity1)
        storage.add(component: transform2, to: entity2)
        
        let entities = storage.entities(with: TransformComponent.self)
        XCTAssertEqual(entities.count, 2)
        XCTAssertTrue(entities.contains(entity1))
        XCTAssertTrue(entities.contains(entity2))
    }
    
    func testEntitiesWithComponentEmpty() {
        let entities = storage.entities(with: TransformComponent.self)
        XCTAssertEqual(entities.count, 0)
    }
    
    func testEntitiesWithDifferentComponents() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        let velocity = VelocityComponent(linear: SIMD2<Float>(5, 5))
        
        storage.add(component: transform, to: entity1)
        storage.add(component: velocity, to: entity2)
        
        let transformEntities = storage.entities(with: TransformComponent.self)
        let velocityEntities = storage.entities(with: VelocityComponent.self)
        
        XCTAssertEqual(transformEntities.count, 1)
        XCTAssertEqual(velocityEntities.count, 1)
        XCTAssertTrue(transformEntities.contains(entity1))
        XCTAssertTrue(velocityEntities.contains(entity2))
    }
    
    // MARK: - Subscript
    
    func testSubscriptGet() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        storage.add(component: transform, to: entity1)
        
        let retrieved = storage[entity1, TransformComponent.self]
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
    }
    
    func testSubscriptSet() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        storage[entity1, TransformComponent.self] = transform
        
        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
    }
    
    func testSubscriptRemove() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        storage.add(component: transform, to: entity1)
        
        storage[entity1, TransformComponent.self] = nil
        
        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
    }
}
