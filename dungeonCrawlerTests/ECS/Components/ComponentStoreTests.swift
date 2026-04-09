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
    var transform1: TransformComponent!
    var transform2: TransformComponent!
    
    override func setUp() {
        super.setUp()
        store = ComponentStore<TransformComponent>()
        entity1 = Entity()
        entity2 = Entity()
        transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
    }
    
    override func tearDown() {
        store = nil
        entity1 = nil
        entity2 = nil
        transform1 = nil
        transform2 = nil
        super.tearDown()
    }
    
    // MARK: - Add & Get
    
    func testAddComponent() {
        store.add(transform1, for: entity1.id)
        
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
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)

        XCTAssertEqual(store.get(for: entity1.id)?.position.x, 10)
        XCTAssertEqual(store.get(for: entity2.id)?.position.x, 30)
    }

    func testOverwriteComponent() {
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity1.id)

        XCTAssertEqual(store.get(for: entity1.id)?.position.x, 30)
        XCTAssertEqual(store.get(for: entity1.id)?.position.y, 40)
    }

    // MARK: - Mutate via reference (replaces old modify tests)

    func testMutateComponent() {
        store.add(transform1, for: entity1.id)

        // Classes: get returns a live reference — mutate directly.
        store.get(for: entity1.id)?.position.x = 100

        let retrieved = store.get(for: entity1.id)
        XCTAssertEqual(retrieved?.position.x, 100)
        XCTAssertEqual(retrieved?.position.y, 20)
    }

    func testMutateNonexistentComponentDoesNotCrash() {
        // get returns nil for a missing entity — optional chaining silently does nothing.
        store.get(for: entity1.id)?.position.x = 100
        XCTAssertNil(store.get(for: entity1.id))
    }

    func testMutateMultipleFields() {
        store.add(transform1, for: entity1.id)

        if let t = store.get(for: entity1.id) {
            t.position = SIMD2<Float>(100, 200)
            t.rotation = 3.14
            t.scale    = 2.0
        }

        let retrieved = store.get(for: entity1.id)
        XCTAssertNotNil(retrieved)
        if let r = retrieved {
            XCTAssertEqual(r.position.x, 100)
            XCTAssertEqual(r.position.y, 200)
            XCTAssertEqual(r.rotation, 3.14 as Float, accuracy: 0.01)
            XCTAssertEqual(r.scale, 2.0)
        }
    }

    func testGetReturnsSameReference() {
        // Class semantics: two calls to get() return the same object identity.
        store.add(transform1, for: entity1.id)

        let ref1 = store.get(for: entity1.id)
        let ref2 = store.get(for: entity1.id)
        XCTAssertTrue(ref1 === ref2)
    }

    func testMutationViaCapturedReferenceIsVisible() {
        // Mutating a reference obtained earlier is immediately visible via a fresh get().
        store.add(transform1, for: entity1.id)

        let ref = store.get(for: entity1.id)!
        ref.position.x = 99

        XCTAssertEqual(store.get(for: entity1.id)?.position.x, 99)
    }

    // MARK: - Remove

    func testRemoveComponent() {
        store.add(transform1, for: entity1.id)

        XCTAssertNotNil(store.get(for: entity1.id))

        store.removeValue(for: entity1.id)

        XCTAssertNil(store.get(for: entity1.id))
    }

    func testRemoveNonexistentComponent() {
        store.removeValue(for: entity1.id)
        XCTAssertNil(store.get(for: entity1.id))
    }

    func testRemoveOneOfMany() {
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
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)

        let entities = store.entities
        XCTAssertEqual(entities.count, 2)
        XCTAssertTrue(entities.contains(entity1))
        XCTAssertTrue(entities.contains(entity2))
    }

    func testEntitiesAfterRemoval() {
        store.add(transform1, for: entity1.id)
        store.add(transform2, for: entity2.id)

        store.removeValue(for: entity1.id)

        let entities = store.entities
        XCTAssertEqual(entities.count, 1)
        XCTAssertFalse(entities.contains(entity1))
        XCTAssertTrue(entities.contains(entity2))
    }
}
