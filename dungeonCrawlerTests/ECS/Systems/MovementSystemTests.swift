//
//  MovementSystemTests.swift
//  dungeonCrawlerTests
//

import XCTest
import simd
@testable import dungeonCrawler

final class MovementSystemStatsTests: XCTestCase {

    private var world: World!
    private let system = MovementSystem()

    override func setUp() {
        super.setUp()
        world = World()
    }

    /// Creates an entity with a unit move direction (1, 0), so velocity magnitude == speed.
    private func makeEntity(stats: StatsComponent? = nil) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        if let stats = stats {
            world.addComponent(component: stats, to: entity)
        }
        return entity
    }

    private func velocityMagnitude(for entity: Entity) -> Float {
        let linear = world.getComponent(type: VelocityComponent.self, for: entity)?.linear ?? .zero
        return simd_length(linear)
    }

    func testSpeedReadFromStatsComponent() {
        let entity = makeEntity(stats: StatsComponent(stats: [.moveSpeed: StatValue(base: 120)]))

        system.update(deltaTime: 0, world: world)

        XCTAssertEqual(velocityMagnitude(for: entity), 120, accuracy: 0.001)
    }

    func testFallbackSpeedUsedWithoutStatsComponent() {
        let entity = makeEntity()

        system.update(deltaTime: 0, world: world)

        XCTAssertEqual(velocityMagnitude(for: entity), system.fallbackMoveSpeed, accuracy: 0.001)
    }

    func testFallbackSpeedUsedWhenMoveSpeedKeyAbsent() {
        let entity = makeEntity(stats: StatsComponent(stats: [.health: StatValue(base: 100)]))

        system.update(deltaTime: 0, world: world)

        XCTAssertEqual(velocityMagnitude(for: entity), system.fallbackMoveSpeed, accuracy: 0.001)
    }

    func testModifiedCurrentSpeedIsUsed() {
        var moveSpeed = StatValue(base: 90)
        moveSpeed.current = 50
        let entity = makeEntity(stats: StatsComponent(stats: [.moveSpeed: moveSpeed]))

        system.update(deltaTime: 0, world: world)

        XCTAssertEqual(velocityMagnitude(for: entity), 50, accuracy: 0.001)
    }
}
