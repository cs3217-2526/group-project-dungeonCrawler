//
//  TimidStrategyTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 10/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class TimidStrategyTests: XCTestCase {

    // MARK: - Properties
    var world: World!
    var enemy: Entity!

    // Strategies
    var strategy: TimidStrategy!
    var customThresholdStrategy: TimidStrategy!
    var hysteresisStrategy: TimidStrategy!

    // Behaviours
    var wanderBehaviour: WanderBehaviour!
    var chaseBehaviour: ChaseBehaviour!
    var fleeBehaviour: FleeBehaviour!

    // Components
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var health: HealthComponent!

    // Context
    var context: BehaviourContext!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()

        // 1. Core ECS
        world = World()
        enemy = world.createEntity()

        // 2. Behaviours
        wanderBehaviour = WanderBehaviour()
        chaseBehaviour = ChaseBehaviour()
        fleeBehaviour = FleeBehaviour()

        // 3. Strategies
        strategy = TimidStrategy(detectionRadius: 150, fleeThreshold: 0.2)
        customThresholdStrategy = TimidStrategy(fleeThreshold: 0.5)
        hysteresisStrategy = TimidStrategy(detectionRadius: 150, loseRadius: 225)

        // 4. Components
        transform = TransformComponent(position: .zero)
        velocity = VelocityComponent()
        health = HealthComponent(base: 100) // Default 100 HP

        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)
        world.addComponent(component: health, to: enemy)

        // 5. Default Context
        context = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
    }

    override func tearDown() {
        // Nil everything to ensure MainActor deallocation
        context = nil
        health = nil
        velocity = nil
        transform = nil

        fleeBehaviour = nil
        chaseBehaviour = nil
        wanderBehaviour = nil

        hysteresisStrategy = nil
        customThresholdStrategy = nil
        strategy = nil

        enemy = nil
        world = nil

        super.tearDown()
    }

    // MARK: - Helpers

    private func activeBehaviourID(for entity: Entity) -> String? {
        world.getComponent(type: ActiveBehaviourComponent.self, for: entity)?.behaviourID
    }

    // MARK: - Default initialisation

    func testDefaultFleeThreshold() {
        XCTAssertEqual(TimidStrategy().fleeThreshold, 0.2, accuracy: 0.001)
    }

    // MARK: - Wander when idle and healthy

    func testWandersWhenHealthyAndPlayerOutOfRange() {
        health.value.current = 100
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), wanderBehaviour.id)
    }

    // MARK: - Attack when healthy and in range

    func testAttacksWhenHealthyAndPlayerWithinDetectionRadius() {
        health.value.current = 100
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), chaseBehaviour.id)
    }

    // MARK: - Flee when low HP

    func testFleesWhenHPBelowThreshold() {
        health.value.current = 15 // 15% HP
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), fleeBehaviour.id)
    }

    func testFleeOverridesAttackWhenLowHP() {
        health.value.current = 10 // 10% HP
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), fleeBehaviour.id,
                       "Flee should override attack even when player is within detection radius")
    }

    func testDoesNotFleeWhenHPIsExactlyAtThreshold() {
        health.value.current = 20 // exactly 20% HP
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), wanderBehaviour.id)
    }

    func testCustomFleeThreshold() {
        health.value.current = 40 // 40% HP
        customThresholdStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), fleeBehaviour.id)
    }

    // MARK: - Behaviour transition lifecycle
    // todo: fix
//    func testWanderTargetRemovedWhenSwitchingToFlee() {
//        health.value.current = 100
//        // Wander first
//        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))
//
//        // Capture component to prevent SIGABRT during removal
//        let wanderTarget = world.getComponent(type: WanderTargetComponent.self, for: enemy)
//        XCTAssertNotNil(wanderTarget)
//
//        // HP drops - switch to flee
//        health.value.current = 10
//        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))
//
//        XCTAssertEqual(activeBehaviourID(for: enemy), fleeBehaviour.id)
//        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))
//    }

    // MARK: - Hysteresis

    func testHysteresisStillAppliesForAttackWhileHealthy() {
        health.value.current = 100
        // Enter chase
        hysteresisStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        XCTAssertEqual(activeBehaviourID(for: enemy), chaseBehaviour.id)

        // Player retreats slightly
        hysteresisStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(180, 0), transform: transform, world: world))
        XCTAssertEqual(activeBehaviourID(for: enemy), chaseBehaviour.id)
    }
}
