//
//  KnockbackSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 19/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class KnockbackSystemTests: XCTestCase {

    var world: World!
    var system: KnockbackSystem!
    var entity1: Entity!
    var entity2: Entity!
    var transform1: TransformComponent!
    var transform2: TransformComponent!
    var knockback1: KnockbackComponent!
    var knockback2: KnockbackComponent!
    var diagKnockback: KnockbackComponent!

    override func setUp() {
        super.setUp()
        world      = World()
        system     = KnockbackSystem()
        entity1    = world.createEntity()
        entity2    = world.createEntity()
        transform1 = TransformComponent(position: .zero)
        transform2 = TransformComponent(position: .zero)
        knockback1 = KnockbackComponent(velocity: SIMD2<Float>(100, 0), remainingTime: 1.0)
        knockback2 = KnockbackComponent(velocity: SIMD2<Float>(0, 100), remainingTime: 1.0)
        diagKnockback = KnockbackComponent(velocity: SIMD2<Float>(-200, 150), remainingTime: 1.0)
    }

    override func tearDown() {
        world      = nil
        system     = nil
        entity1    = nil
        entity2    = nil
        transform1 = nil
        transform2 = nil
        knockback1 = nil
        knockback2 = nil
        diagKnockback = nil
        super.tearDown()
    }

    // MARK: - Position integration

    func testKnockbackMovesEntityByVelocityTimesDeltaTime() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: knockback1, to: entity1)

        system.update(deltaTime: 0.5, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.position.x ?? 0, 50, accuracy: 0.001)
        XCTAssertEqual(transform?.position.y ?? 0, 0, accuracy: 0.001)
    }

    func testKnockbackMovesInCorrectDirection() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: diagKnockback, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertEqual(transform?.position.x ?? 0, -200, accuracy: 0.001)
        XCTAssertEqual(transform?.position.y ?? 0, 150, accuracy: 0.001)
    }

    // MARK: - Timer countdown

    func testRemainingTimeDecreasesByDeltaTime() {
        knockback1.remainingTime = 0.5
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: knockback1, to: entity1)

        system.update(deltaTime: 0.2, world: world)

        let kb = world.getComponent(type: KnockbackComponent.self, for: entity1)
        XCTAssertNotNil(kb)
        XCTAssertEqual(kb?.remainingTime ?? 0, 0.3, accuracy: 0.001)
    }

    // MARK: - Component removal

    func testKnockbackComponentRemovedWhenExpired() {
        knockback1.remainingTime = 0.1
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: knockback1, to: entity1)

        system.update(deltaTime: 0.2, world: world)

        XCTAssertNil(world.getComponent(type: KnockbackComponent.self, for: entity1))
    }

    func testKnockbackComponentKeptWhenNotExpired() {
        knockback1.remainingTime = 0.5
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: knockback1, to: entity1)

        system.update(deltaTime: 0.1, world: world)

        XCTAssertNotNil(world.getComponent(type: KnockbackComponent.self, for: entity1))
    }

    // MARK: - Entities without knockback unaffected

    func testEntityWithoutKnockbackNotMoved() {
        transform1.position = SIMD2<Float>(50, 50)
        world.addComponent(component: transform1, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertEqual(transform?.position.x ?? 0, 50, accuracy: 0.001)
        XCTAssertEqual(transform?.position.y ?? 0, 50, accuracy: 0.001)
    }

    // MARK: - Multiple entities

    func testMultipleEntitiesHandledIndependently() {
        world.addComponent(component: transform1, to: entity1)
        world.addComponent(component: knockback1, to: entity1) // Velocity (100, 0)

        world.addComponent(component: transform2, to: entity2)
        world.addComponent(component: knockback2, to: entity2) // Velocity (0, 100)

        system.update(deltaTime: 1.0, world: world)

        let t1 = world.getComponent(type: TransformComponent.self, for: entity1)
        let t2 = world.getComponent(type: TransformComponent.self, for: entity2)
        
        XCTAssertEqual(t1?.position.x ?? 0, 100, accuracy: 0.001)
        XCTAssertEqual(t1?.position.y ?? 0, 0,   accuracy: 0.001)
        XCTAssertEqual(t2?.position.x ?? 0, 0,   accuracy: 0.001)
        XCTAssertEqual(t2?.position.y ?? 0, 100, accuracy: 0.001)
    }
}
