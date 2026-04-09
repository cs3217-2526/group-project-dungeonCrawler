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
    var strategy: WanderStrategy!
    
    // Properties for tracked entities and components
    var enemy: Entity!
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var wanderTarget: WanderTargetComponent!
    var customStrat1: WanderStrategy!
    var customStrat2: WanderStrategy!
    var customStrat3: WanderStrategy!

    override func setUp() {
        super.setUp()
        world = World()
        strategy = WanderStrategy()
        
        // Initialize components
        transform = TransformComponent(position: .zero)
        velocity = VelocityComponent()
        
        // Initialize main test entity
        enemy = world.createEntity()
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)
        
        // wanderTarget is typically added lazily by the strategy
        customStrat1 = WanderStrategy(wanderRadius: 200)
        customStrat2 = WanderStrategy(wanderSpeed: 60)
        customStrat3 = WanderStrategy(wanderSpeed: 50)
    }

    override func tearDown() {
        world = nil
        strategy = nil
        enemy = nil
        transform = nil
        velocity = nil
        wanderTarget = nil
        customStrat1 = nil
        customStrat2 = nil
        customStrat3 = nil
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
        XCTAssertEqual(strategy.wanderRadius, 100, accuracy: 0.001)
    }

    func testDefaultWanderSpeed() {
        XCTAssertEqual(strategy.wanderSpeed, 40, accuracy: 0.001)
    }

    func testCustomWanderRadius() {
        XCTAssertEqual(customStrat1.wanderRadius, 200, accuracy: 0.001)
    }

    func testCustomWanderSpeed() {
        XCTAssertEqual(customStrat2.wanderSpeed, 60, accuracy: 0.001)
    }

    // MARK: - Lazy WanderTargetComponent

    func testWanderTargetComponentAbsentBeforeFirstUpdate() {
        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy),
                     "WanderTargetComponent should not exist before first update")
    }

    func testWanderTargetComponentAddedOnFirstUpdate() {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        XCTAssertNotNil(world.getComponent(type: WanderTargetComponent.self, for: enemy),
                        "WanderTargetComponent should be added lazily on first update")
    }

    // MARK: - Update behaviour

    func testUpdateProducesNonZeroVelocity() {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        XCTAssertGreaterThan(simd_length(velocity.linear), 0,
                             "WanderStrategy should produce non-zero velocity on first update")
    }

    func testVelocityMagnitudeEqualsWanderSpeed() {
        customStrat3.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        XCTAssertEqual(simd_length(velocity.linear), 50, accuracy: 0.01,
                       "Velocity magnitude should equal wanderSpeed")
    }

    func testWanderTargetMinRadiusFloor() {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)

        let target = world.getComponent(type: WanderTargetComponent.self, for: enemy)?.target
        XCTAssertNotNil(target)
        XCTAssertGreaterThan(simd_length(target! - transform.position), 0,
                             "Target should be above the minRadius floor")
    }

    // MARK: - Target persistence

    func testWanderTargetPersistedBetweenUpdates() throws {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        
        let comp1 = try XCTUnwrap(world.getComponent(type: WanderTargetComponent.self, for: enemy))
        let target1 = comp1.target

        // Same position — target should not be re-rolled
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        
        let comp2 = try XCTUnwrap(world.getComponent(type: WanderTargetComponent.self, for: enemy))
        let target2 = comp2.target

        XCTAssertEqual(target1!.x, target2!.x, accuracy: Float(0.001),
                       "Wander target should persist while enemy hasn't arrived")
        XCTAssertEqual(target1!.y, target2!.y, accuracy: Float(0.001))
    }

    func testVelocityDirectionIsConsistentBeforeArrival() {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        let vel1 = velocity.linear

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(999, 999), world: world)
        let vel2 = velocity.linear

        XCTAssertEqual(vel1.x, vel2.x, accuracy: 0.001,
                       "Velocity direction should not change before arrival at wander target")
        XCTAssertEqual(vel1.y, vel2.y, accuracy: 0.001)
    }
}
