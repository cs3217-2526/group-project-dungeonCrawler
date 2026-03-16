//
//  EntityFactoryTests.swift
//  dungeonCrawlerTests
//
//  Created by Ger Teck on 17/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

final class EntityFactoryTests: XCTestCase {

    var world: World!

    override func setUp() {
        super.setUp()
        world = World()
    }

    override func tearDown() {
        world = nil
        super.tearDown()
    }

    func testMakePlayerEntityIsAlive() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        // Entity is alive if we can query a component from it
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
    }

    func testMakePlayerTransform() {
        let position = SIMD2<Float>(100, 200)
        let entity = EntityFactory.makePlayer(in: world, at: position)
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.position.x, 100, accuracy: 0.001)
        XCTAssertEqual(transform!.position.y, 200, accuracy: 0.001)
    }

    func testMakePlayerVelocity() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
        XCTAssertNotNil(velocity)
        XCTAssertEqual(velocity!.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity!.linear.y, 0, accuracy: 0.001)
    }

    func testMakePlayerInput() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: entity))
    }

    func testMakePlayerSprite() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
        XCTAssertNotNil(sprite)
        XCTAssertEqual(sprite!.textureName, "knight")
    }

    func testMakePlayerCustomTexture() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0), textureName: "warrior")
        let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
        XCTAssertNotNil(sprite)
        XCTAssertEqual(sprite!.textureName, "warrior")
    }

    func testMakePlayerTag() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        XCTAssertNotNil(world.getComponent(type: PlayerTagComponent.self, for: entity))
    }

    func testMakePlayerHealth() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let health = world.getComponent(type: HealthComponent.self, for: entity)
        XCTAssertNotNil(health)
        XCTAssertEqual(health!.value.base, 100, accuracy: 0.001)
        XCTAssertEqual(health!.value.current, 100, accuracy: 0.001)
    }

    func testMakePlayerMoveSpeed() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let speed = world.getComponent(type: MoveSpeedComponent.self, for: entity)
        XCTAssertNotNil(speed)
        XCTAssertEqual(speed!.value.base, 90, accuracy: 0.001)
        XCTAssertEqual(speed!.value.current, 90, accuracy: 0.001)
    }

    func testMakePlayerReturnsDistinctEntities() {
        let entity1 = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let entity2 = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(10, 10))
        XCTAssertNotEqual(entity1, entity2)
    }
}
