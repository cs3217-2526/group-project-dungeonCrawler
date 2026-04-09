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
    var strategy: StraightLineChaseStrategy!
    
    // Properties for tracked entities and components
    var enemy: Entity!
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var customStrat1: StraightLineChaseStrategy!
    var customStrat2: StraightLineChaseStrategy!
    

    override func setUp() {
        super.setUp()
        world    = World()
        strategy = StraightLineChaseStrategy()
        
        // Initialize components
        transform = TransformComponent(position: SIMD2<Float>(0, 0))
        velocity  = VelocityComponent()
        
        // Initialize main test entity
        enemy = world.createEntity()
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)
        
        customStrat1 = StraightLineChaseStrategy(chaseSpeed: 120)
        customStrat2 = StraightLineChaseStrategy(chaseSpeed: 90)
    }

    override func tearDown() {
        world     = nil
        strategy  = nil
        enemy     = nil
        transform = nil
        velocity  = nil
        super.tearDown()
    }

    // MARK: - Default initialisation

    func testDefaultChaseSpeed() {
        XCTAssertEqual(strategy.chaseSpeed, 70, accuracy: 0.001)
    }

    func testCustomChaseSpeed() {
        XCTAssertEqual(customStrat1.chaseSpeed, 120, accuracy: 0.001)
    }

    // MARK: - Update behaviour

    func testVelocityPointsTowardPlayer() {
        // Player is at (100, 0), enemy at (0, 0)
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 0), world: world)

        XCTAssertGreaterThan(velocity.linear.x, 0, "Velocity x should be positive when player is to the right")
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001, "Velocity y should be zero when player is on same horizontal")
    }

    func testVelocityMagnitudeEqualsChaseSpeed() {
        customStrat2.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 50), world: world)

        XCTAssertEqual(simd_length(velocity.linear), 90, accuracy: 0.01,
                       "Velocity magnitude should always equal chaseSpeed regardless of direction")
    }

    func testVelocityPointsAwayFromPlayerWhenBehind() {
        // Enemy at (100, 0), player at (0, 0)
        transform.position = SIMD2(100, 0)
        
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)

        XCTAssertLessThan(velocity.linear.x, 0, "Velocity x should be negative when player is to the left")
    }

    // MARK: - Edge case: enemy at same position as player

    func testNoVelocityChangeWhenAtPlayerPosition() {
        transform.position = SIMD2(50, 50)
        velocity.linear = .zero

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(50, 50), world: world)

        XCTAssertEqual(velocity.linear.x, 0, accuracy: 0.001,
                       "Velocity should not change when enemy is already at player position")
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001)
    }
}
