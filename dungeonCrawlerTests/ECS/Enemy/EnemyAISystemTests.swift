//
//  EnemyAISystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 19/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class EnemyAISystemTests: XCTestCase {

    var world: World!
    var system: EnemyAISystem!

    override func setUp() {
        super.setUp()
        world = World()
        system = EnemyAISystem()
    }

    override func tearDown() {
        world = nil
        system = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @discardableResult
    private func makePlayer(at position: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        return entity
    }

    @discardableResult
    private func makeEnemy(at position: SIMD2<Float>,
                            detectionRadius: Float = 150,
                            loseRadius: Float = 225) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyStateComponent(detectionRadius: detectionRadius,
                                                          loseRadius: loseRadius), to: entity)
        return entity
    }

    // MARK: - No player

    func testNoUpdateWithoutPlayer() {
        let enemy = makeEnemy(at: SIMD2(0, 0))
        system.update(deltaTime: 1.0, world: world)
        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)
        XCTAssertEqual(vel!.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel!.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - Chase mode

    func testEnemySwitchesToChaseWhenPlayerWithinDetectionRadius() {
        makePlayer(at: SIMD2(100, 0))
        let enemy = makeEnemy(at: SIMD2(0, 0), detectionRadius: 150)

        system.update(deltaTime: 0.1, world: world)

        let state = world.getComponent(type: EnemyStateComponent.self, for: enemy)
        XCTAssertNotNil(state)
        XCTAssertTrue(state!.mode == .chase)
    }

    func testEnemyVelocityPointsTowardPlayerWhenChasing() {
        makePlayer(at: SIMD2(100, 0))
        let enemy = makeEnemy(at: SIMD2(0, 0), detectionRadius: 150)

        system.update(deltaTime: 0.1, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)
        XCTAssertNotNil(vel)
        XCTAssertGreaterThan(vel!.linear.x, 0)
        XCTAssertEqual(vel!.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - Wander mode

    func testEnemyStaysInWanderWhenPlayerBeyondLoseRadius() {
        makePlayer(at: SIMD2(300, 0))
        let enemy = makeEnemy(at: SIMD2(0, 0), detectionRadius: 150, loseRadius: 225)

        system.update(deltaTime: 0.1, world: world)

        let state = world.getComponent(type: EnemyStateComponent.self, for: enemy)
        XCTAssertNotNil(state)
        XCTAssertTrue(state!.mode == .wander)
    }

    func testEnemyInWanderProducesNonZeroVelocity() {
        makePlayer(at: SIMD2(300, 0))
        let enemy = makeEnemy(at: SIMD2(0, 0), detectionRadius: 150, loseRadius: 225)

        system.update(deltaTime: 0.1, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)
        XCTAssertNotNil(vel)
        XCTAssertGreaterThan(simd_length(vel!.linear), 0,
                             "Wander strategy should produce a non-zero velocity toward its target")
    }

    // MARK: - Knockback suppression, enemyAI shouldnt interfere

    func testEnemyInKnockbackIsSkipped() {
        makePlayer(at: SIMD2(50, 0))
        let enemy = makeEnemy(at: SIMD2(0, 0), detectionRadius: 150)
        world.addComponent(component: KnockbackComponent(velocity: SIMD2(-100, 0), remainingTime: 0.3), to: enemy)

        system.update(deltaTime: 0.1, world: world)

        // Enemy is within detection range but should be skipped due to knockback
        let state = world.getComponent(type: EnemyStateComponent.self, for: enemy)
        XCTAssertTrue(state!.mode == .wander)
    }

    func testEnemyVelocityNotOverwrittenDuringKnockback() {
        makePlayer(at: SIMD2(50, 0))
        let enemy = makeEnemy(at: SIMD2(0, 0), detectionRadius: 150)
        let knockbackVel = SIMD2<Float>(-100, 0)
        world.addComponent(component: KnockbackComponent(velocity: knockbackVel, remainingTime: 0.3), to: enemy)

        system.update(deltaTime: 0.1, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)
        XCTAssertEqual(vel!.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel!.linear.y, 0, accuracy: 0.001)
    }
}
