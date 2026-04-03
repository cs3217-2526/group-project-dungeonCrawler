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
    private func makeEnemy(at position: SIMD2<Float>,
                           velocity: SIMD2<Float> = .zero) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        world.addComponent(component: VelocityComponent(linear: velocity), to: entity)
        return entity
    }

    // MARK: - Tests

    func testVelocityUnchangedWhenAlreadyZero() {
        let strategy = StationaryStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 0), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    func testVelocityUnchangedWhenNonZero() {
        let strategy = StationaryStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0), velocity: SIMD2(50, 30))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 0), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 50, accuracy: 0.001,
                       "StationaryStrategy should not modify existing velocity")
        XCTAssertEqual(vel.linear.y, 30, accuracy: 0.001)
    }

    func testPositionUnchangedAfterUpdate() {
        let strategy = StationaryStrategy()
        let enemy = makeEnemy(at: SIMD2(42, 99))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)

        let updatedTransform = world.getComponent(type: TransformComponent.self, for: enemy)!
        XCTAssertEqual(updatedTransform.position.x, 42, accuracy: 0.001)
        XCTAssertEqual(updatedTransform.position.y, 99, accuracy: 0.001)
    }

    func testPlayerPositionHasNoEffect() {
        let strategy = StationaryStrategy()
        let enemy = makeEnemy(at: SIMD2(0, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(500, 500), world: world)
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(-999, 0), world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    func testMultipleUpdatesHaveNoEffect() {
        let strategy = StationaryStrategy()
        let enemy = makeEnemy(at: SIMD2(10, 20))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        for _ in 0..<10 {
            strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(100, 100), world: world)
        }

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }
}
