//
//  StationaryStrategyTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 2/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class StationaryStrategyTests: XCTestCase {

    var world: World!
    var strategy: StationaryStrategy!
    
    // Properties for tracked entities and components
    var enemy: Entity!
    var transform: TransformComponent!
    var velocity: VelocityComponent!

    override func setUp() {
        super.setUp()
        world    = World()
        strategy = StationaryStrategy()
        
        // Initialize components with default test values
        transform = TransformComponent(position: SIMD2<Float>(0, 0))
        velocity  = VelocityComponent(linear: .zero)
        
        // Initialize main test entity
        enemy = world.createEntity()
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)
    }

    override func tearDown() {
        world     = nil
        strategy  = nil
        enemy     = nil
        transform = nil
        velocity  = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testVelocityUnchangedWhenAlreadyZero() {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 0), world: world)

        XCTAssertEqual(velocity.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001)
    }

    func testVelocityUnchangedWhenNonZero() {
        // Modify the tracked velocity to be non-zero
        velocity.linear = SIMD2<Float>(50, 30)

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 0), world: world)

        XCTAssertEqual(velocity.linear.x, 50, accuracy: 0.001,
                       "StationaryStrategy should not modify existing velocity")
        XCTAssertEqual(velocity.linear.y, 30, accuracy: 0.001)
    }

    func testPositionUnchangedAfterUpdate() {
        transform.position = SIMD2<Float>(42, 99)

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)

        XCTAssertEqual(transform.position.x, 42, accuracy: 0.001)
        XCTAssertEqual(transform.position.y, 99, accuracy: 0.001)
    }

    func testPlayerPositionHasNoEffect() {
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(500, 500), world: world)
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(-999, 0), world: world)

        XCTAssertEqual(velocity.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001)
    }

    func testMultipleUpdatesHaveNoEffect() {
        transform.position = SIMD2<Float>(10, 20)

        for _ in 0..<10 {
            strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 100), world: world)
        }

        XCTAssertEqual(velocity.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001)
        XCTAssertEqual(transform.position.x, 10, accuracy: 0.001)
    }
}
