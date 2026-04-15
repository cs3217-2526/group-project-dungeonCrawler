//
//  OrbitBehaviourTest.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 14/4/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

final class OrbitBehaviourTests: XCTestCase {

    // MARK: - Properties
    var world: World!
    var enemy: Entity!

    var behaviour: OrbitBehaviour!
    var customRadiusBehaviour: OrbitBehaviour!
    var customArcBehaviour: OrbitBehaviour!
    var customSpeedBehaviour: OrbitBehaviour!

    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var shooterComponent: ShooterBasicComponent!
    var context: BehaviourContext!
    var context1: BehaviourContext!
    var context2: BehaviourContext!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()

        world = World()
        enemy = world.createEntity()

        behaviour = OrbitBehaviour()
        customRadiusBehaviour = OrbitBehaviour(innerRadius: 100, outerRadius: 200)
        customArcBehaviour = OrbitBehaviour(arcRange: .pi / 3)
        customSpeedBehaviour = OrbitBehaviour(innerRadius: 100, outerRadius: 200, moveSpeed: 60)

        // 3. All Components
        transform = TransformComponent(position: SIMD2(150, 0))
        velocity = VelocityComponent()
        shooterComponent = ShooterBasicComponent()

        // 4. Attach standard components to world
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)

        context = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
        context1 = BehaviourContext(entity: enemy, playerPos: .zero, transform: transform, world: world)
        context2 = BehaviourContext(entity: enemy, playerPos: SIMD2(0, 200), transform: transform, world: world)
    }

    override func tearDown() {
        // Nil everything to ensure MainActor deallocation
        context = nil
        context1 = nil
        context2 = nil
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

    // MARK: - Deactivation Cleanup
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

    // MARK: - Arrival Behaviour

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

    // MARK: - Target Tracks Chase Target

    func testTargetFollowsChaseTargetMovement() {
        transform.position = SIMD2(0, 50)
        shooterComponent.targetAngle = 0
        shooterComponent.targetRadius = 150
        world.addComponent(component: shooterComponent, to: enemy)

        // Player at origin
        behaviour.update(entity: enemy, context: context1)
        let linear1 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        // Player moves up
        behaviour.update(entity: enemy, context: context2)
        let linear2 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        XCTAssertGreaterThan(linear1.x, 0)
        XCTAssertLessThan(linear1.y, 0)
        XCTAssertGreaterThan(linear2.x, 0)
        XCTAssertGreaterThan(linear2.y, 0)
    }
}
