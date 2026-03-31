//
//  StraightLineChaseStrategyTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 28/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class StraightLineChaseStrategyTests: XCTestCase {

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

    func testDefaultChaseSpeed() {
        let strategy = StraightLineChaseStrategy()
        XCTAssertEqual(strategy.chaseSpeed, 70, accuracy: 0.001)
    }

    func testCustomChaseSpeed() {
        let strategy = StraightLineChaseStrategy(chaseSpeed: 120)
        XCTAssertEqual(strategy.chaseSpeed, 120, accuracy: 0.001)
    }

    // MARK: - Update behaviour

    func testVelocityPointsTowardPlayer() {
        let strategy = StraightLineChaseStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 0), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(vel.linear.x, 0, "Velocity x should be positive when player is to the right")
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001, "Velocity y should be zero when player is on same horizontal")
    }

    func testVelocityMagnitudeEqualsChaseSpeed() {
        let strategy = StraightLineChaseStrategy(chaseSpeed: 90)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 50), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(simd_length(vel.linear), 90, accuracy: 0.01,
                       "Velocity magnitude should always equal chaseSpeed regardless of direction")
    }

    func testVelocityPointsAwayFromPlayerWhenBehind() {
        let strategy = StraightLineChaseStrategy()
        let enemy = makeEnemy(at: SIMD2(100, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertLessThan(vel.linear.x, 0, "Velocity x should be negative when player is to the left")
    }

    // MARK: - Edge case: enemy at same position as player

    func testNoVelocityChangeWhenAtPlayerPosition() {
        let strategy = StraightLineChaseStrategy()
        let enemy = makeEnemy(at: SIMD2(50, 50))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(50, 50), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001,
                       "Velocity should not change when enemy is already at player position")
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }
}
