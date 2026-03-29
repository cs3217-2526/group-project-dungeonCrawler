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

    override func setUp() {
        super.setUp()
        world  = World()
        system = InvincibilitySystem()
    }

    override func tearDown() {
        system = nil
        world  = nil
        super.tearDown()
    }

    // MARK: - Timer countdown

    func testRemainingTimeDecreasesByDeltaTime() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.5), to: entity)

        system.update(deltaTime: 0.2, world: world)

        let component = world.getComponent(type: InvincibilityComponent.self, for: entity)
        XCTAssertNotNil(component)
        XCTAssertEqual(component!.remainingTime, 0.3, accuracy: 0.001)
    }

    func testRemainingTimeDecreasesCorrectlyOverMultipleFrames() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.5), to: entity)

        system.update(deltaTime: 0.1, world: world)
        system.update(deltaTime: 0.1, world: world)

        let component = world.getComponent(type: InvincibilityComponent.self, for: entity)
        XCTAssertNotNil(component)
        XCTAssertEqual(component!.remainingTime, 0.3, accuracy: 0.001)
    }

    // MARK: - Component removal when expired

    func testComponentRemovedWhenTimerReachesZero() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.1), to: entity)

        system.update(deltaTime: 0.1, world: world)

        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity))
    }

    func testComponentRemovedWhenTimerGoesNegative() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.1), to: entity)

        system.update(deltaTime: 0.5, world: world)

        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity))
    }

    func testComponentKeptWhenTimerStillPositive() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.5), to: entity)

        system.update(deltaTime: 0.1, world: world)

        XCTAssertNotNil(world.getComponent(type: InvincibilityComponent.self, for: entity))
    }

    // MARK: - Entities without the component are unaffected

    func testEntityWithoutComponentUnaffected() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(), to: entity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
    }

    func testEmptyWorldDoesNotCrash() {
        system.update(deltaTime: 0.016, world: world)
    }

    // MARK: - Multiple entities handled independently

    func testMultipleEntitiesTickedIndependently() {
        let entityA = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.3), to: entityA)

        let entityB = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.1), to: entityB)

        system.update(deltaTime: 0.2, world: world)

        // A should still be invincible (0.3 - 0.2 = 0.1)
        let compA = world.getComponent(type: InvincibilityComponent.self, for: entityA)
        XCTAssertNotNil(compA)
        XCTAssertEqual(compA!.remainingTime, 0.1, accuracy: 0.001)

        // B should have expired (0.1 - 0.2 < 0)
        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entityB))
    }
}
