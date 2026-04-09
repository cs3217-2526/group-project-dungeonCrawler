//
//  InvicibilitySystemTest.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 30/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class InvincibilitySystemTests: XCTestCase {

    var world: World!
    var system: InvincibilitySystem!
    var entity1: Entity!
    var entity2: Entity!
    var invincibility1: InvincibilityComponent!
    var invincibility2: InvincibilityComponent!
    var transform: TransformComponent!

    override func setUp() {
        super.setUp()
        world = World()
        system = InvincibilitySystem()
        entity1 = world.createEntity()
        entity2 = world.createEntity()
        invincibility1 = InvincibilityComponent(remainingTime: 0.5)
        invincibility2 = InvincibilityComponent(remainingTime: 0.1)
        transform = TransformComponent()
    }

    override func tearDown() {
        world = nil
        system = nil
        entity1 = nil
        entity2 = nil
        invincibility1 = nil
        invincibility2 = nil
        transform = nil
        super.tearDown()
    }

    // MARK: - Timer countdown

    func testRemainingTimeDecreasesByDeltaTime() {
        world.addComponent(component: invincibility1, to: entity1)

        system.update(deltaTime: 0.2, world: world)

        let component = world.getComponent(type: InvincibilityComponent.self, for: entity1)
        XCTAssertNotNil(component)
        XCTAssertEqual(component?.remainingTime ?? 0, 0.3, accuracy: 0.001)
    }

    func testRemainingTimeDecreasesCorrectlyOverMultipleFrames() {
        world.addComponent(component: invincibility1, to: entity1)

        system.update(deltaTime: 0.1, world: world)
        system.update(deltaTime: 0.1, world: world)

        let component = world.getComponent(type: InvincibilityComponent.self, for: entity1)
        XCTAssertNotNil(component)
        XCTAssertEqual(component?.remainingTime ?? 0, 0.3, accuracy: 0.001)
    }

    // MARK: - Component removal when expired

    func testComponentRemovedWhenTimerReachesZero() {
        world.addComponent(component: invincibility2, to: entity1)

        system.update(deltaTime: 0.1, world: world)

        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity1))
    }

    func testComponentRemovedWhenTimerGoesNegative() {
        world.addComponent(component: invincibility2, to: entity1)

        system.update(deltaTime: 0.5, world: world)

        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity1))
    }

    func testComponentKeptWhenTimerStillPositive() {
        world.addComponent(component: invincibility1, to: entity1)

        system.update(deltaTime: 0.1, world: world)

        XCTAssertNotNil(world.getComponent(type: InvincibilityComponent.self, for: entity1))
    }

    // MARK: - Entities without the component are unaffected

    func testEntityWithoutComponentUnaffected() {
        world.addComponent(component: transform, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity1))
    }

    func testEmptyWorldDoesNotCrash() {
        // Destroy the entities created in setup to test a truly empty update
        world.destroyAllEntities()
        system.update(deltaTime: 0.016, world: world)
    }

    // MARK: - Multiple entities handled independently

    func testMultipleEntitiesTickedIndependently() {
        world.addComponent(component: invincibility1, to: entity1) // 0.5s
        
        // Custom time for second component to match original test logic (0.1s)
        world.addComponent(component: invincibility2, to: entity2) // 0.1s

        system.update(deltaTime: 0.2, world: world)

        // entity1 should still be invincible (0.5 - 0.2 = 0.3)
        let compA = world.getComponent(type: InvincibilityComponent.self, for: entity1)
        XCTAssertNotNil(compA)
        XCTAssertEqual(compA?.remainingTime ?? 0, 0.3, accuracy: 0.001)

        // entity2 should have expired (0.1 - 0.2 < 0)
        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity2))
    }
}
