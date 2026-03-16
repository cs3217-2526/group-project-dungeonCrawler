//
//  HealthSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Ger Teck on 17/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class HealthSystemTests: XCTestCase {

    var world: World!
    var system: HealthSystem!

    override func setUp() {
        super.setUp()
        world = World()
        system = HealthSystem()
    }

    override func tearDown() {
        system = nil
        world = nil
        super.tearDown()
    }

    func testPriority() {
        XCTAssertEqual(system.priority, 15)
    }

    func testEntityDestroyedAtZeroHealth() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: entity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: entity))
    }

    func testEntityDestroyedAtNegativeHealth() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = -1
        world.addComponent(component: health, to: entity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: entity))
    }

    func testEntitySurvivesPositiveHealth() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 50
        world.addComponent(component: health, to: entity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: entity))
    }

    func testEntitySurvivesAtOneHP() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 1
        world.addComponent(component: health, to: entity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: entity))
    }

    func testOnlyZeroHPEntitiesDestroyed() {
        let dead = world.createEntity()
        var deadHealth = HealthComponent(base: 100)
        deadHealth.value.current = 0
        world.addComponent(component: deadHealth, to: dead)

        let alive = world.createEntity()
        var aliveHealth = HealthComponent(base: 100)
        aliveHealth.value.current = 50
        world.addComponent(component: aliveHealth, to: alive)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: dead))
        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: alive))
    }

    func testEntityWithoutHealthComponentUnaffected() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(), to: entity)

        // Should not crash
        system.update(deltaTime: 0.016, world: world)

        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
    }

    func testEmptyWorldDoesNotCrash() {
        system.update(deltaTime: 0.016, world: world)
    }

    func testDestroyedEntityLosesAllComponents() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: entity)
        world.addComponent(component: TransformComponent(), to: entity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: entity))
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity))
    }
}
