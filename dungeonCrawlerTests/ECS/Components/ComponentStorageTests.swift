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
    var transform1: TransformComponent!
    var transform2: TransformComponent!
    var velocity1: VelocityComponent!
    var input1: InputComponent!
    
    override func setUp() {
        super.setUp()
        storage = ComponentStorage()
        entity1 = Entity()
        entity2 = Entity()
        transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        transform2 = TransformComponent(position: SIMD2<Float>(30, 40))
        velocity1 = VelocityComponent(linear: SIMD2<Float>(5, 5))
        input1 = InputComponent()
    }
    
    override func tearDown() {
        storage = nil
        entity1 = nil
        entity2 = nil
        transform1 = nil
        transform2 = nil
        velocity1 = nil
        input1 = nil
        super.tearDown()
    }
    
    // MARK: - Add & Get
    
    func testAddAndGetComponent() {
        storage.add(component: transform1, to: entity1)
        
        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.position.x, 10)
        XCTAssertEqual(retrieved?.position.y, 20)
    }
    
    func testAddMultipleComponentTypes() {
        storage.add(component: transform1, to: entity1)
        storage.add(component: velocity1,  to: entity1)
        storage.add(component: input1,     to: entity1)
        
        XCTAssertNotNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNotNil(storage.get(type: VelocityComponent.self,  for: entity1))
        XCTAssertNotNil(storage.get(type: InputComponent.self,     for: entity1))
    }
    
    func testGetNonexistentComponent() {
        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertNil(retrieved)
    }
    
    func testAddSameComponentToDifferentEntities() {
        storage.add(component: transform1, to: entity1)
        storage.add(component: transform2, to: entity2)

        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity1)?.position.x, 10)
        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity2)?.position.x, 30)
    }

    // MARK: - Mutate via reference (replaces old modify tests)

    func testMutateComponent() {
        storage.add(component: transform1, to: entity1)

        storage.get(type: TransformComponent.self, for: entity1)?.position.x = 100

        let retrieved = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertEqual(retrieved?.position.x, 100)
        XCTAssertEqual(retrieved?.position.y, 20)
    }

    func testMutateNonexistentComponentDoesNotCrash() {
        // Optional chaining on nil silently does nothing — should not crash.
        storage.get(type: TransformComponent.self, for: entity1)?.position.x = 100
        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
    }

    func testGetReturnsSameReference() {
        // Two calls to get() for the same entity return the same object identity.
        storage.add(component: transform1, to: entity1)

        let ref1 = storage.get(type: TransformComponent.self, for: entity1)
        let ref2 = storage.get(type: TransformComponent.self, for: entity1)
        XCTAssertTrue(ref1 === ref2)
    }

    func testMutationViaCapturedReferenceIsVisible() {
        // A reference captured before mutation reflects changes when re-fetched.
        storage.add(component: transform1, to: entity1)

        let ref = storage.get(type: TransformComponent.self, for: entity1)!
        ref.position.x = 99

        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity1)?.position.x, 99)
    }

    func testEntitiesAreIndependent() {
        // Mutating entity1's component must not affect entity2's.
        storage.add(component: transform1, to: entity1)
        storage.add(component: transform2, to: entity2)

        storage.get(type: TransformComponent.self, for: entity1)?.position.x = 999

        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity1)?.position.x, 999)
        XCTAssertEqual(storage.get(type: TransformComponent.self, for: entity2)?.position.x, 30)
    }

    // MARK: - Remove

    func testRemoveSpecificComponent() {
        storage.add(component: transform1, to: entity1)
        storage.add(component: velocity1,  to: entity1)

        storage.remove(type: TransformComponent.self, from: entity1)

        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNotNil(storage.get(type: VelocityComponent.self, for: entity1))
    }

    func testRemoveAllComponents() {
        storage.add(component: transform1, to: entity1)
        storage.add(component: velocity1,  to: entity1)
        storage.add(component: input1,     to: entity1)

        storage.removeAll(from: entity1)

        XCTAssertNil(storage.get(type: TransformComponent.self, for: entity1))
        XCTAssertNil(storage.get(type: VelocityComponent.self,  for: entity1))
        XCTAssertNil(storage.get(type: InputComponent.self,     for: entity1))
    }

    func testRemoveAllDoesNotAffectOtherEntities() {
        storage.add(component: transform1, to: entity1)
        storage.add(component: transform2, to: entity2)

        storage.removeAll(from: entity1)

        XCTAssertNil(storage.get(type: TransformComponent.self,  for: entity1))
        XCTAssertNotNil(storage.get(type: TransformComponent.self, for: entity2))
    }

    // MARK: - Entities Query

    func testEntitiesWithComponent() {
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
        storage.add(component: transform1, to: entity1)
        storage.add(component: velocity1,  to: entity2)

        let transformEntities = storage.entities(with: TransformComponent.self)
        let velocityEntities  = storage.entities(with: VelocityComponent.self)

        XCTAssertEqual(transformEntities.count, 1)
        XCTAssertEqual(velocityEntities.count,  1)
        XCTAssertTrue(transformEntities.contains(entity1))
        XCTAssertTrue(velocityEntities.contains(entity2))
    }
}
