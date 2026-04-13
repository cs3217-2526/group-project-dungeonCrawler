//
//  StandardStrategyTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 10/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class StandardStrategyTests: XCTestCase {

    // MARK: - Properties
    var world: World!
    var enemy: Entity!

    // Strategies
    var strategy: StandardStrategy!
    var shooterStrategy: StandardStrategy!
    var infiniteChaseStrategy: StandardStrategy!

    // Behaviours (for ID comparison)
    var wanderBehaviour: WanderBehaviour!
    var chaseBehaviour: ChaseBehaviour!
    var shooterBehaviour: ShooterBehaviour!

    // Components
    var transform: TransformComponent!
    var velocity: VelocityComponent!

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
        shooterBehaviour = ShooterBehaviour()

        // 3. Strategies
        strategy = StandardStrategy(detectionRadius: 150, loseRadius: 225)
        shooterStrategy = StandardStrategy(detectionRadius: 150, attackBehaviour: shooterBehaviour)
        infiniteChaseStrategy = StandardStrategy(detectionRadius: 150, loseRadius: nil)

        // 4. Components
        transform = TransformComponent(position: .zero)
        velocity = VelocityComponent()

        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)

        // 5. Default Context
        context = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
    }

    override func tearDown() {
        // Nil everything to ensure MainActor deallocation
        context = nil
        velocity = nil
        transform = nil

        shooterBehaviour = nil
        chaseBehaviour = nil
        wanderBehaviour = nil

        infiniteChaseStrategy = nil
        shooterStrategy = nil
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

    func testDefaultDetectionRadius() {
        XCTAssertEqual(StandardStrategy().detectionRadius, 150, accuracy: 0.001)
    }

    func testDefaultLoseRadius() throws {
        let loseRadius = try XCTUnwrap(StandardStrategy().loseRadius)
        XCTAssertEqual(loseRadius, 225, accuracy: 0.001)
    }

    // MARK: - Wander when idle

    func testWandersWhenPlayerOutsideDetectionRadius() {
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), wanderBehaviour.id)
    }

    // MARK: - Hysteresis

    func testKeepsChasingBetweenDetectionAndLoseRadius() {
        // Enter attack range
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        let attackID = activeBehaviourID(for: enemy)

        // Player retreats slightly
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(180, 0), transform: transform, world: world))
        XCTAssertEqual(activeBehaviourID(for: enemy), attackID, "Should keep attacking while player is within loseRadius")
    }

    func testReturnsToWanderWhenPlayerExceedsLoseRadius() {
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(300, 0), transform: transform, world: world))

        XCTAssertEqual(activeBehaviourID(for: enemy), wanderBehaviour.id)
    }

    // MARK: - nil loseRadius

    func testNeverDisengagesWhenLoseRadiusIsNil() {
        infiniteChaseStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        infiniteChaseStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(1000, 0), transform: transform, world: world))

        XCTAssertNotEqual(activeBehaviourID(for: enemy), wanderBehaviour.id)
    }

    // MARK: - Behaviour transition lifecycle
    // TODO: fix
//    func testWanderTargetRemovedWhenSwitchingToAttack() {
//        // Wander first
//        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(200, 0), transform: transform, world: world))
//
//        // Capture to prevent deallocation crash during removal
//        let wanderTarget = world.getComponent(type: WanderTargetComponent.self, for: enemy)
//        XCTAssertNotNil(wanderTarget)
//
//        // Switch to attack
//        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
//        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))
//    }

    // MARK: - With Chase attack behaviour

    func testActivatesChaseBehaviourWhenPlayerInRange() {
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        XCTAssertEqual(activeBehaviourID(for: enemy), chaseBehaviour.id)
    }

    func testChaseVelocityPointsTowardPlayer() {
        strategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(vel.linear.x, 0)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - With Shooter attack behaviour

    func testActivatesShooterBehaviourWhenPlayerInRange() {
        shooterStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        XCTAssertEqual(activeBehaviourID(for: enemy), shooterBehaviour.id)
    }

    func testShooterComponentAddedWhenEngaging() {
        shooterStrategy.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    // TODO: Fix
//    func testShooterComponentRemovedWhenDisengaging() {
//        let strategyWithLose = StandardStrategy(detectionRadius: 150, loseRadius: 225, attackBehaviour: shooterBehaviour)
//
//        // Enter shooter attack
//        strategyWithLose.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(100, 0), transform: transform, world: world))
//
//        // Capture shooter component to prevent SIGABRT during state switch
//        let shooterComp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)
//        XCTAssertNotNil(shooterComp)
//
//        // Disengage
//        strategyWithLose.update(entity: enemy, context: BehaviourContext(entity: enemy, playerPos: SIMD2(300, 0), transform: transform, world: world))
//        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
//    }
}
