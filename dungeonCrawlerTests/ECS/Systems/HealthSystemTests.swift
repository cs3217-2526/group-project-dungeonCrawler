//
//  HealthSystemTests.swift
//  dungeonCrawlerTests
//

import XCTest
@testable import dungeonCrawler

final class HealthSystemTests: XCTestCase {

    private var world: World!
    private let system = HealthSystem()

    override func setUp() {
        super.setUp()
        world = World()
    }

    func testEntityWithPositiveHealthSurvives() {
        let entity = world.createEntity()
        world.addComponent(component: StatsComponent(stats: [.health: StatValue(base: 100)]), to: entity)

        system.update(deltaTime: 0, world: world)

        XCTAssertTrue(world.isAlive(entity: entity))
    }

    func testEntityWithZeroHealthIsDestroyed() {
        let entity = world.createEntity()
        var health = StatValue(base: 100)
        health.current = 0
        world.addComponent(component: StatsComponent(stats: [.health: health]), to: entity)

        system.update(deltaTime: 0, world: world)

        XCTAssertFalse(world.isAlive(entity: entity))
    }

    func testEntityWithNegativeHealthIsDestroyed() {
        let entity = world.createEntity()
        var health = StatValue(base: 100)
        health.current = -1
        world.addComponent(component: StatsComponent(stats: [.health: health]), to: entity)

        system.update(deltaTime: 0, world: world)

        XCTAssertFalse(world.isAlive(entity: entity))
    }

    func testEntityWithoutStatsComponentIsUnaffected() {
        let entity = world.createEntity()

        system.update(deltaTime: 0, world: world)

        XCTAssertTrue(world.isAlive(entity: entity))
    }

    func testEntityWithStatsButNoHealthKeyIsUnaffected() {
        let entity = world.createEntity()
        world.addComponent(component: StatsComponent(stats: [.attack: StatValue(base: 10)]), to: entity)

        system.update(deltaTime: 0, world: world)

        XCTAssertTrue(world.isAlive(entity: entity))
    }
}
