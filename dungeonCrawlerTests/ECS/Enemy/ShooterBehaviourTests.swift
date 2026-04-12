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

    private func makeContext(entity: Entity, playerPos: SIMD2<Float>) -> BehaviourContext {
        let transform = world.getComponent(type: TransformComponent.self, for: entity)!
        return BehaviourContext(entity: entity, playerPos: playerPos, transform: transform, world: world)
    }

    /// Pre-attaches a ShooterBasicComponent with a known target in polar coords
    /// relative to the player, bypassing the random pick on first update.
    private func setTarget(on entity: Entity, angle: Float, radius: Float) {
        let comp = ShooterBasicComponent()
        comp.targetAngle = angle
        comp.targetRadius = radius
        world.addComponent(component: comp, to: entity)
    }

    // MARK: - Lazy Component Attachment

    func testLazilyAttachesComponentOnFirstUpdate() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    func testComponentPersistsBetweenUpdates() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))
        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    // MARK: - Deactivation cleanup

    func testShooterComponentRemovedOnDeactivate() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        let context = makeContext(entity: enemy, playerPos: .zero)

        behaviour.update(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))

        behaviour.onDeactivate(entity: enemy, context: context)
        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy),
                     "ShooterBasicComponent should be removed on deactivate")
    }

    // MARK: - First Update (no target yet)

    func testVelocityIsZeroOnFirstUpdate() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    func testTargetIsPickedOnFirstUpdate() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        XCTAssertNotNil(comp.targetAngle)
        XCTAssertNotNil(comp.targetRadius)
    }

    func testTargetRadiusWithinAnnulus() {
        let behaviour = ShooterBehaviour(innerRadius: 100, outerRadius: 200)
        let enemy = makeEnemy(at: SIMD2(150, 0))

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let radius = comp.targetRadius!
        XCTAssertGreaterThanOrEqual(radius, 100)
        XCTAssertLessThanOrEqual(radius, 200)
    }

    func testTargetAngleWithinArcRange() {
        let arcRange: Float = .pi / 3
        let behaviour = ShooterBehaviour(arcRange: arcRange)
        let enemy = makeEnemy(at: SIMD2(150, 0))

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let angle = comp.targetAngle!
        XCTAssertLessThanOrEqual(abs(angle), arcRange + 0.001,
                                 "Target angle should be within ±arcRange of current angle")
    }

    // MARK: - Movement Toward Target

    func testVelocityPointsTowardTarget() {
        let behaviour = ShooterBehaviour(innerRadius: 100, outerRadius: 200, moveSpeed: 60)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        setTarget(on: enemy, angle: 0, radius: 150)

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(vel.linear.x, 0, "Velocity x should be positive when target is to the right")
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.01)
    }

    func testVelocityMagnitudeEqualsMoveSpeed() {
        let moveSpeed: Float = 75
        let behaviour = ShooterBehaviour(innerRadius: 100, outerRadius: 200, moveSpeed: moveSpeed)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        setTarget(on: enemy, angle: .pi / 4, radius: 150)

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(simd_length(vel.linear), moveSpeed, accuracy: 0.01)
    }

    // MARK: - Arrival behaviour

    func testVelocityZeroOnArrival() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        setTarget(on: enemy, angle: 0, radius: 150)

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    func testNewTargetPickedOnArrival() {
        let behaviour = ShooterBehaviour()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        setTarget(on: enemy, angle: 0, radius: 150)

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: .zero))

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        XCTAssertNotNil(comp.targetAngle, "A new target should be picked after arrival")
        XCTAssertNotNil(comp.targetRadius)
    }

    // MARK: - Target tracks chase target

    func testTargetFollowsChaseTargetMovement() {
        let behaviour = ShooterBehaviour(moveSpeed: 60)
        let enemy = makeEnemy(at: SIMD2(0, 50))
        setTarget(on: enemy, angle: 0, radius: 150)

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(0, 0)))
        let vel1 = world.getComponent(type: VelocityComponent.self, for: enemy)!

        behaviour.update(entity: enemy, context: makeContext(entity: enemy, playerPos: SIMD2(0, 200)))
        let vel2 = world.getComponent(type: VelocityComponent.self, for: enemy)!

        XCTAssertGreaterThan(vel1.linear.x, 0)
        XCTAssertLessThan(vel1.linear.y, 0, "Enemy should move down when target is below")
        XCTAssertGreaterThan(vel2.linear.x, 0)
        XCTAssertGreaterThan(vel2.linear.y, 0, "Enemy should move up when target is above")
    }

    // MARK: - Default parameters

    func testDefaultInnerRadius() {
        XCTAssertEqual(ShooterBehaviour().innerRadius, 100, accuracy: 0.001)
    }

    func testDefaultOuterRadius() {
        XCTAssertEqual(ShooterBehaviour().outerRadius, 200, accuracy: 0.001)
    }

    func testDefaultMoveSpeed() {
        XCTAssertEqual(ShooterBehaviour().moveSpeed, 60, accuracy: 0.001)
    }

    func testDefaultArcRange() {
        XCTAssertEqual(ShooterBehaviour().arcRange, .pi / 3, accuracy: 0.001)
    }
}
