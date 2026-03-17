//
//  ComponentStoreTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler
 
final class ComponentStoreTests: XCTestCase {
    
    var store: ComponentStore<TransformComponent>!
    var entity1: Entity!
    var entity2: Entity!
    
    override func setUp() {
        super.setUp()
        store = ComponentStore<TransformComponent>()
        entity1 = Entity()
        entity2 = Entity()
    }
    
    override func tearDown() {
        store = nil
        entity1 = nil
        entity2 = nil
        super.tearDown()
    }
    
    // MARK: - Add & Get
    
    func testAddComponent() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        store.add(transform, for: entity1.id)
        
        let retrieved = store.get(for: entity1.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testGetNonexistentComponent() {
        let retrieved = store.get(for: entity1.id)
        XCTAssertNil(retrieved)
    }
    
    func testAddMultipleComponents() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)
        
        XCTAssertEqual(store.get(for: entity1.id)?.position.x, 10)
        XCTAssertEqual(store.get(for: entity2.id)?.position.x, 30)
    }
    
    func testOverwriteComponent() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity1.id)
        
        let retrieved = store.get(for: entity1.id)
        XCTAssertEqual(retrieved?.position.x, 30)
        XCTAssertEqual(retrieved?.position.y, 40)
    }
    
    // MARK: - Modify
    
    func testModifyComponent() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        store.add(transform, for: entity1.id)
        
        store.modify(for: entity1.id) { component in
            component.position.x = 100
        }
        
        let retrieved = store.get(for: entity1.id)
        XCTAssertEqual(retrieved?.position.x, 100)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testModifyNonexistentComponent() {
        // Should not crash when modifying a component that doesn't exist
        store.modify(for: entity1.id) { component in
            component.position.x = 100
        }
        
        // Component should still not exist
        XCTAssertNil(store.get(for: entity1.id))
    }
    
    func testModifyMultipleFields() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20), rotation: 0, scale: 1)
        store.add(transform, for: entity1.id)
        
        store.modify(for: entity1.id) { component in
            component.position = SIMD2<Float>(100, 200)
            component.rotation = 3.14
            component.scale = 2.0
        }
        
        let retrieved = store.get(for: entity1.id)
        let r = try? XCTUnwrap(retrieved)
        XCTAssertNotNil(r)
        if let r {
            XCTAssertEqual(r.position.x, 100)
            XCTAssertEqual(r.position.y, 200)
            XCTAssertEqual(r.rotation, 3.14 as Float, accuracy: 0.01)
            XCTAssertEqual(r.scale, 2.0)
        }
    }
    
    // MARK: - Remove
    
    func testRemoveComponent() {
        let transform = TransformComponent(position: SIMD2<Float>(10, 20))
        store.add(transform, for: entity1.id)
        
        XCTAssertNotNil(store.get(for: entity1.id))
        
        store.removeValue(for: entity1.id)
        
        XCTAssertNil(store.get(for: entity1.id))
    }
    
    func testRemoveNonexistentComponent() {
        // Should not crash when removing a component that doesn't exist
        store.removeValue(for: entity1.id)
        XCTAssertNil(store.get(for: entity1.id))
    }
    
    func testRemoveOneOfMany() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)
        
        store.removeValue(for: entity1.id)
        
        XCTAssertNil(store.get(for: entity1.id))
        XCTAssertNotNil(store.get(for: entity2.id))
        XCTAssertEqual(store.get(for: entity2.id)?.position.x, 30)
    }
    
    // MARK: - Entities
    
    func testEntitiesEmpty() {
        XCTAssertEqual(store.entities.count, 0)
    }
    
    func testEntitiesWithComponents() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)
        
        let entities = store.entities
        XCTAssertEqual(entities.count, 2)
        XCTAssertTrue(entities.contains(entity1))
        XCTAssertTrue(entities.contains(entity2))
    }
    
    func testEntitiesAfterRemoval() {
        let transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)
        
        store.removeValue(for: entity1.id)
        
        let entities = store.entities
        XCTAssertEqual(entities.count, 1)
        XCTAssertFalse(entities.contains(entity1))
        XCTAssertTrue(entities.contains(entity2))
    }
}

