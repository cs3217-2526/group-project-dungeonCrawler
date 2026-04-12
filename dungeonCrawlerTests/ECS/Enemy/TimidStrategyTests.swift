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
    private func makeEnemy(at position: SIMD2<Float>, currentHP: Float = 100) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        if currentHP != 100 {
            world.getComponent(type: HealthComponent.self, for: entity)?.value.current = currentHP
        }
        return entity
    }

    private func makeContext(entity: Entity, playerPos: SIMD2<Float>) -> BehaviourContext {
        let transform = world.getComponent(type: TransformComponent.self, for: entity)!
        return BehaviourContext(entity: entity, playerPos: playerPos, transform: transform, world: world)
    }

    private func activeBehaviourID(for entity: Entity) -> String? {
        world.getComponent(type: ActiveBehaviourComponent.self, for: entity)?.behaviourID
    }

    // MARK: - Default initialisation

    func testDefaultFleeThreshold() {
        XCTAssertEqual(TimidStrategy().fleeThreshold, 0.2, accuracy: 0.001)
    }

    // MARK: - Wander when idle and healthy

    func testWandersWhenHealthyAndPlayerOutOfRange() {
        let strategy = TimidStrategy(detectionRadius: 150)
        let enemy = makeEnemy(at: .zero, currentHP: 100)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), WanderBehaviour().id)
    }

    // MARK: - Attack when healthy and in range

    func testAttacksWhenHealthyAndPlayerWithinDetectionRadius() {
        let strategy = TimidStrategy(detectionRadius: 150)
        let enemy = makeEnemy(at: .zero, currentHP: 100)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), ChaseBehaviour().id)
    }

    // MARK: - Flee when low HP

    func testFleesWhenHPBelowThreshold() {
        let strategy = TimidStrategy(detectionRadius: 150, fleeThreshold: 0.2)
        let enemy = makeEnemy(at: .zero, currentHP: 15) // 15% HP

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), FleeBehaviour().id)
    }

    func testFleeOverridesAttackWhenLowHP() {
        let strategy = TimidStrategy(detectionRadius: 150, fleeThreshold: 0.2)
        let enemy = makeEnemy(at: .zero, currentHP: 10) // 10% HP, within detection radius

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), FleeBehaviour().id,
                       "Flee should override attack even when player is within detection radius")
    }

    func testDoesNotFleeWhenHPIsExactlyAtThreshold() {
        let strategy = TimidStrategy(detectionRadius: 150, fleeThreshold: 0.2)
        let enemy = makeEnemy(at: .zero, currentHP: 20) // exactly 20% HP

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), WanderBehaviour().id,
                       "Should not flee when HP is exactly at threshold — condition is strictly less than")
    }

    func testCustomFleeThreshold() {
        let strategy = TimidStrategy(fleeThreshold: 0.5)
        let enemy = makeEnemy(at: .zero, currentHP: 40) // 40% HP, below 50% threshold

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), FleeBehaviour().id)
    }

    // MARK: - Behaviour transition lifecycle

    func testWanderTargetRemovedWhenSwitchingToFlee() {
        let strategy = TimidStrategy(detectionRadius: 150, fleeThreshold: 0.2)
        let enemy = makeEnemy(at: .zero, currentHP: 100)

        // Wander first — WanderTargetComponent gets added lazily
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))
        XCTAssertNotNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))

        // HP drops below threshold — should switch to flee and clean up wander state
        world.getComponent(type: HealthComponent.self, for: enemy)?.value.current = 10
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), FleeBehaviour().id)
        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy),
                     "WanderTargetComponent should be removed when switching from wander to flee")
    }

    func testHysteresisStillAppliesForAttackWhileHealthy() {
        let strategy = TimidStrategy(detectionRadius: 150, loseRadius: 225)
        let enemy = makeEnemy(at: .zero, currentHP: 100)

        // Enter chase
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))
        XCTAssertEqual(activeBehaviourID(for: enemy), ChaseBehaviour().id)

        // Player retreats to between detection and lose radius — should stay chasing
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(180, 0)))
        XCTAssertEqual(activeBehaviourID(for: enemy), ChaseBehaviour().id,
                       "Hysteresis should still apply for attack transitions when healthy")
    }
}
