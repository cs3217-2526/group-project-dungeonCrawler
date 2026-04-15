//
//  ShooterBehaviourTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 9/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class ShooterBehaviourTests: XCTestCase {

    // MARK: - Properties
    var world: World!
    var enemy: Entity!

    var behaviour: ShooterBehaviour!

    var transform: TransformComponent!
    var context: BehaviourContext!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()

        world = World()
        enemy = world.createEntity()

        behaviour = ShooterBehaviour()

        transform = TransformComponent(position: SIMD2(150, 0))
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: VelocityComponent(), to: enemy)

        context = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
    }

    override func tearDown() {
        context = nil
        transform = nil
        behaviour = nil
        enemy = nil
        world = nil
        super.tearDown()
    }

    // MARK: - onActivate

    func testActivateAddsFacingComponent() {
        XCTAssertNil(world.getComponent(type: FacingComponent.self, for: enemy))
        behaviour.onActivate(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: FacingComponent.self, for: enemy))
    }

    func testActivateAddsInputComponent() {
        XCTAssertNil(world.getComponent(type: InputComponent.self, for: enemy))
        behaviour.onActivate(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: enemy))
    }

    func testActivateEquipsWeapon() {
        behaviour.onActivate(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: EquippedWeaponComponent.self, for: enemy))
    }

    // MARK: - onDeactivate
    // TODO: fix
//
//    func testDeactivateClearsShooting() {
//        behaviour.onActivate(entity: enemy, context: context)
//        world.getComponent(type: InputComponent.self, for: enemy)?.isShooting = true
//
//        behaviour.onDeactivate(entity: enemy, context: context)
//
//        XCTAssertEqual(
//            world.getComponent(type: InputComponent.self, for: enemy)?.isShooting,
//            false
//        )
//    }
//
//    func testDeactivateRemovesEquippedWeapon() {
//        behaviour.onActivate(entity: enemy, context: context)
//        behaviour.onDeactivate(entity: enemy, context: context)
//        XCTAssertNil(world.getComponent(type: EquippedWeaponComponent.self, for: enemy))
//    }

    // MARK: - Update: aim

    func testUpdateSetsAimDirectionTowardPlayer() {
        behaviour.onActivate(entity: enemy, context: context)
        // enemy at (150, 0), player at (0, 0) → aim should point left (negative x)
        behaviour.update(entity: enemy, context: context)

        let aim = world.getComponent(type: InputComponent.self, for: enemy)!.aimDirection
        XCTAssertLessThan(aim.x, 0)
        XCTAssertEqual(aim.y, 0, accuracy: 0.001)
    }

    func testUpdateSetsIsShootingTrue() {
        behaviour.onActivate(entity: enemy, context: context)
        behaviour.update(entity: enemy, context: context)

        XCTAssertTrue(world.getComponent(type: InputComponent.self, for: enemy)!.isShooting)
    }

    func testUpdateDoesNotWriteVelocity() {
        behaviour.onActivate(entity: enemy, context: context)
        behaviour.update(entity: enemy, context: context)

        // ShooterBehaviour must never touch VelocityComponent
        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }
}
