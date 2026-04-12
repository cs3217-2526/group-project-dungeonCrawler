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

    private func makeContext(entity: Entity, playerPos: SIMD2<Float>) -> BehaviourContext {
        let transform = world.getComponent(type: TransformComponent.self, for: entity)!
        return BehaviourContext(entity: entity, playerPos: playerPos, transform: transform, world: world)
    }

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

    // MARK: - Wander when idle (applies to all configurations)

    func testWandersWhenPlayerOutsideDetectionRadius() {
        let strategy = StandardStrategy(detectionRadius: 150)
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), WanderBehaviour().id)
    }

    // MARK: - Hysteresis (applies to all configurations)

    func testKeepsChasingBetweenDetectionAndLoseRadius() {
        let strategy = StandardStrategy(detectionRadius: 150, loseRadius: 225)
        let enemy = makeEnemy(at: .zero)

        // Enter attack range
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))
        let attackID = activeBehaviourID(for: enemy)

        // Player retreats to between detection and lose radius — should still be attacking
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(180, 0)))
        XCTAssertEqual(activeBehaviourID(for: enemy), attackID,
                       "Should keep attacking while player is within loseRadius")
    }

    func testReturnsToWanderWhenPlayerExceedsLoseRadius() {
        let strategy = StandardStrategy(detectionRadius: 150, loseRadius: 225)
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(300, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), WanderBehaviour().id,
                       "Should return to wander once player exceeds loseRadius")
    }

    // MARK: - nil loseRadius (applies to all configurations)

    func testNeverDisengagesWhenLoseRadiusIsNil() {
        let strategy = StandardStrategy(detectionRadius: 150, loseRadius: nil)
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(1000, 0)))

        XCTAssertNotEqual(activeBehaviourID(for: enemy), WanderBehaviour().id,
                          "Should never return to wander when loseRadius is nil")
    }

    // MARK: - Behaviour transition lifecycle (applies to all configurations)

    func testWanderTargetRemovedWhenSwitchingToAttack() {
        let strategy = StandardStrategy(detectionRadius: 150)
        let enemy = makeEnemy(at: .zero)

        // Wander first — WanderTargetComponent added lazily
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(200, 0)))
        XCTAssertNotNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))

        // Switch to attack — onDeactivate should remove WanderTargetComponent
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))
        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy),
                     "WanderTargetComponent should be removed when switching from wander to attack")
    }

    // MARK: - With Chase attack behaviour (default)

    func testActivatesChaseBehaviourWhenPlayerInRange() {
        let strategy = StandardStrategy(detectionRadius: 150)
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), ChaseBehaviour().id)
    }

    func testChaseVelocityPointsTowardPlayer() {
        let strategy = StandardStrategy(detectionRadius: 150)
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(vel.linear.x, 0, "Velocity should point toward player when chasing")
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - With Shooter attack behaviour

    func testActivatesShooterBehaviourWhenPlayerInRange() {
        let strategy = StandardStrategy(detectionRadius: 150, attackBehaviour: ShooterBehaviour())
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))

        XCTAssertEqual(activeBehaviourID(for: enemy), ShooterBehaviour().id)
    }

    func testShooterComponentAddedWhenEngaging() {
        let strategy = StandardStrategy(detectionRadius: 150, attackBehaviour: ShooterBehaviour())
        let enemy = makeEnemy(at: .zero)

        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy),
                        "ShooterBasicComponent should be added lazily when ShooterBehaviour activates")
    }

    func testShooterComponentRemovedWhenDisengaging() {
        let strategy = StandardStrategy(detectionRadius: 150, loseRadius: 225,
                                        attackBehaviour: ShooterBehaviour())
        let enemy = makeEnemy(at: .zero)

        // Enter shooter attack
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(100, 0)))
        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))

        // Player moves beyond lose radius — ShooterBasicComponent should be cleaned up
        strategy.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(300, 0)))
        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy),
                     "ShooterBasicComponent should be removed when switching from shooter to wander")
    }
}
