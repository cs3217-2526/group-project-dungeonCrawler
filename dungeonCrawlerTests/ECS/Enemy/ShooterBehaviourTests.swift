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

    // Behaviours
    var behaviour: ShooterBehaviour!
    var customRadiusBehaviour: ShooterBehaviour!
    var customArcBehaviour: ShooterBehaviour!
    var customSpeedBehaviour: ShooterBehaviour!

    // Components
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var shooterComponent: ShooterBasicComponent!

    // Context
    var context: BehaviourContext!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()

        // 1. Core ECS
        world = World()
        enemy = world.createEntity()

        // 2. All Behaviour Variations
        behaviour = ShooterBehaviour()
        customRadiusBehaviour = ShooterBehaviour(innerRadius: 100, outerRadius: 200)
        customArcBehaviour = ShooterBehaviour(arcRange: .pi / 3)
        customSpeedBehaviour = ShooterBehaviour(innerRadius: 100, outerRadius: 200, moveSpeed: 60)

        // 3. All Components
        transform = TransformComponent(position: SIMD2(150, 0))
        velocity = VelocityComponent()
        shooterComponent = ShooterBasicComponent()

        // 4. Attach standard components to world
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)

        // 5. Context
        context = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
    }

    override func tearDown() {
        // Nil everything to ensure MainActor deallocation
        context = nil
        shooterComponent = nil
        velocity = nil
        transform = nil

        customSpeedBehaviour = nil
        customArcBehaviour = nil
        customRadiusBehaviour = nil
        behaviour = nil

        enemy = nil
        world = nil

        super.tearDown()
    }

    // MARK: - Lazy Component Attachment

    func testLazilyAttachesComponentOnFirstUpdate() {
        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
        behaviour.update(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    func testComponentPersistsBetweenUpdates() {
        behaviour.update(entity: enemy, context: context)
        behaviour.update(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    // MARK: - Deactivation cleanup
    // TODO: fix
//    func testShooterComponentRemovedOnDeactivate() {
//        behaviour.update(entity: enemy, context: context)
//        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
//
//        behaviour.onDeactivate(entity: enemy, context: context)
//        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
//    }

    // MARK: - First Update (no target yet)

    func testVelocityIsZeroOnFirstUpdate() {
        behaviour.update(entity: enemy, context: context)
        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - Behaviour Parameter Tests

    func testTargetRadiusWithinAnnulus() {
        customRadiusBehaviour.update(entity: enemy, context: context)
        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let radius = comp.targetRadius!
        XCTAssertGreaterThanOrEqual(radius, 100)
        XCTAssertLessThanOrEqual(radius, 200)
    }

    func testTargetAngleWithinArcRange() {
        customArcBehaviour.update(entity: enemy, context: context)
        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let angle = comp.targetAngle!
        XCTAssertLessThanOrEqual(abs(angle), (.pi / 3) + 0.001)
    }

    // MARK: - Movement Toward Target

    func testVelocityPointsTowardTarget() {
        transform.position = .zero
        shooterComponent.targetAngle = 0
        shooterComponent.targetRadius = 150
        world.addComponent(component: shooterComponent, to: enemy)

        customSpeedBehaviour.update(entity: enemy, context: context)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(vel.linear.x, 0)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.01)
    }

    // MARK: - Arrival behaviour

    func testVelocityZeroOnArrival() {
        shooterComponent.targetAngle = 0
        shooterComponent.targetRadius = 150
        world.addComponent(component: shooterComponent, to: enemy)
        transform.position = SIMD2(150, 0)

        behaviour.update(entity: enemy, context: context)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - Target tracks chase target

    func testTargetFollowsChaseTargetMovement() {
        transform.position = SIMD2(0, 50)
        shooterComponent.targetAngle = 0
        shooterComponent.targetRadius = 150
        world.addComponent(component: shooterComponent, to: enemy)

        // Player at origin
        let context1 = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
        behaviour.update(entity: enemy, context: context1)
        let linear1 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        // Player moves up
        let context2 = BehaviourContext(entity: enemy, playerPos: SIMD2(0, 200), transform: transform, world: world)
        behaviour.update(entity: enemy, context: context2)
        let linear2 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        XCTAssertGreaterThan(linear1.x, 0)
        XCTAssertLessThan(linear1.y, 0)
        XCTAssertGreaterThan(linear2.x, 0)
        XCTAssertGreaterThan(linear2.y, 0)
    }
}
