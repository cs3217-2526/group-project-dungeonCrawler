//
//  WanderStrategyTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 28/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class WanderStrategyTests: XCTestCase {

    var world: World!

    override func setUp() {
        super.setUp()
        world = World()
    }

    override func tearDown() {
        world = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @discardableResult
    private func makeEnemy(at position: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        return entity
    }

    // MARK: - Default initialisation

    func testDefaultWanderRadius() {
        let strategy = WanderStrategy()
        XCTAssertEqual(strategy.wanderRadius, 100, accuracy: 0.001)
    }

    func testDefaultWanderSpeed() {
        let strategy = WanderStrategy()
        XCTAssertEqual(strategy.wanderSpeed, 40, accuracy: 0.001)
    }

    func testCustomWanderRadius() {
        let strategy = WanderStrategy(wanderRadius: 200)
        XCTAssertEqual(strategy.wanderRadius, 200, accuracy: 0.001)
    }

    func testCustomWanderSpeed() {
        let strategy = WanderStrategy(wanderSpeed: 60)
        XCTAssertEqual(strategy.wanderSpeed, 60, accuracy: 0.001)
    }

    // MARK: - Lazy WanderTargetComponent

    func testWanderTargetComponentAbsentBeforeFirstUpdate() {
        let enemy = makeEnemy(at: SIMD2(0, 0))
        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy),
                     "WanderTargetComponent should not exist before first update")
    }

    func testWanderTargetComponentAddedOnFirstUpdate() {
        let strategy = WanderStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        XCTAssertNotNil(world.getComponent(type: WanderTargetComponent.self, for: enemy),
                        "WanderTargetComponent should be added lazily on first update")
    }

    // MARK: - Update behaviour

    func testUpdateProducesNonZeroVelocity() {
        let strategy = WanderStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(simd_length(vel.linear), 0,
                             "WanderStrategy should produce non-zero velocity on first update")
    }

    func testVelocityMagnitudeEqualsWanderSpeed() {
        let strategy = WanderStrategy(wanderSpeed: 50)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(simd_length(vel.linear), 50, accuracy: 0.01,
                       "Velocity magnitude should equal wanderSpeed")
    }

    func testWanderTargetIsWithinWanderRadius() {
        let strategy = WanderStrategy(wanderRadius: 100)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        for _ in 0..<20 {
            strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
            let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
            XCTAssertGreaterThan(simd_length(vel.linear), 0,
                                 "Should always find a valid wander target within radius")
        }
    }

    func testWanderTargetMinRadiusFloor() {
        let strategy = WanderStrategy(wanderRadius: 100)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        let target = world.getComponent(type: WanderTargetComponent.self, for: enemy)?.target
        XCTAssertNotNil(target)
        XCTAssertGreaterThan(simd_length(target! - transform.position), 0,
                             "Target should be above the minRadius floor")
    }

    // MARK: - Target persistence

    func testWanderTargetPersistedBetweenUpdates() throws {
        let strategy = WanderStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        let target1 = world.getComponent(type: WanderTargetComponent.self, for: enemy)!.target

        // Same position — target should not be re-rolled
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        let target2 = world.getComponent(type: WanderTargetComponent.self, for: enemy)!.target

        let t1 = try XCTUnwrap(target1)
        let t2 = try XCTUnwrap(target2)
        XCTAssertEqual(t1.x, t2.x, accuracy: 0.001,
                       "Wander target should persist while enemy hasn't arrived")
        XCTAssertEqual(t1.y, t2.y, accuracy: 0.001)
    }

    func testVelocityDirectionIsConsistentBeforeArrival() {
        let strategy = WanderStrategy(wanderRadius: 100, wanderSpeed: 40)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        let vel1 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        let vel2 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        XCTAssertEqual(vel1.x, vel2.x, accuracy: 0.001,
                       "Velocity direction should not change before arrival at wander target")
        XCTAssertEqual(vel1.y, vel2.y, accuracy: 0.001)
    }
}
