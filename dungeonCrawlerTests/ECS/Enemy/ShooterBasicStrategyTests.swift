//
//  ShooterBasicStrategyTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 3/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class ShooterBasicStrategyTests: XCTestCase {

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

    /// Pre-attaches a ShooterBasicComponent with a known target expressed in polar coords
    /// relative to the player, bypassing the random pick on first update.
    private func setTarget(on entity: Entity, angle: Float, radius: Float) {
        var comp = ShooterBasicComponent()
        comp.targetAngle = angle
        comp.targetRadius = radius
        world.addComponent(component: comp, to: entity)
    }

    // MARK: - Lazy Component Attachment

    func testLazilyAttachesComponentOnFirstUpdate() {
        let strategy = ShooterBasicStrategy()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))

        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    func testComponentPersistsBetweenUpdates() {
        let strategy = ShooterBasicStrategy()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    // MARK: - First Update (no target yet)

    func testVelocityIsZeroOnFirstUpdate() {
        // No target on first update → arrived = true → velocity zeroed
        let strategy = ShooterBasicStrategy()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    func testTargetIsPickedOnFirstUpdate() {
        let strategy = ShooterBasicStrategy()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        XCTAssertNotNil(comp.targetAngle)
        XCTAssertNotNil(comp.targetRadius)
    }

    func testTargetRadiusWithinAnnulus() {
        let strategy = ShooterBasicStrategy(innerRadius: 100, outerRadius: 200)
        let enemy = makeEnemy(at: SIMD2(150, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let radius = comp.targetRadius!
        XCTAssertGreaterThanOrEqual(radius, 100)
        XCTAssertLessThanOrEqual(radius, 200)
    }

    func testTargetAngleWithinArcRange() {
        // Enemy at (150, 0) relative to player at origin → currentAngle = 0
        // New target angle should be within ±arcRange of 0
        let arcRange: Float = .pi / 3
        let strategy = ShooterBasicStrategy(arcRange: arcRange)
        let enemy = makeEnemy(at: SIMD2(150, 0))
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let angle = comp.targetAngle!
        XCTAssertLessThanOrEqual(abs(angle), arcRange + 0.001,
                                 "Target angle should be within ±arcRange of current angle")
    }

    // MARK: - Movement Toward Target

    func testVelocityPointsTowardTarget() {
        // Target at angle=0, radius=150 → world pos (150, 0); enemy at (0, 0) → moves right
        let strategy = ShooterBasicStrategy(innerRadius: 100, outerRadius: 200, moveSpeed: 60)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        setTarget(on: enemy, angle: 0, radius: 150)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(vel.linear.x, 0, "Velocity x should be positive when target is to the right")
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.01)
    }

    func testVelocityMagnitudeEqualsMoveSpeed() {
        let moveSpeed: Float = 75
        let strategy = ShooterBasicStrategy(innerRadius: 100, outerRadius: 200, moveSpeed: moveSpeed)
        let enemy = makeEnemy(at: SIMD2(0, 0))
        setTarget(on: enemy, angle: .pi / 4, radius: 150)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(simd_length(vel.linear), moveSpeed, accuracy: 0.01)
    }

    // MARK: - Arrival Behaviour

    func testVelocityZeroOnArrival() {
        // Enemy at (150, 0), target world pos = (150, 0) → distance = 0 → arrived
        let strategy = ShooterBasicStrategy()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        setTarget(on: enemy, angle: 0, radius: 150)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(vel.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(vel.linear.y, 0, accuracy: 0.001)
    }

    func testNewTargetPickedOnArrival() {
        let strategy = ShooterBasicStrategy()
        let enemy = makeEnemy(at: SIMD2(150, 0))
        setTarget(on: enemy, angle: 0, radius: 150)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        XCTAssertNotNil(comp.targetAngle, "A new target should be picked after arrival")
        XCTAssertNotNil(comp.targetRadius)
    }

    // MARK: - Target Tracks Player

    func testTargetFollowsPlayerMovement() {
        // Target stored as polar (angle=0, radius=150) tracks the player's world position.
        // Enemy at (0, 50) — far enough from both targets not to trigger arrival.
        let strategy = ShooterBasicStrategy(moveSpeed: 60)
        let enemy = makeEnemy(at: SIMD2(0, 50))
        setTarget(on: enemy, angle: 0, radius: 150)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)!

        // Player at (0, 0) → target world pos (150, 0) → enemy moves right and down
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)
        let vel1 = world.getComponent(type: VelocityComponent.self, for: enemy)!

        // Player at (0, 200) → target world pos (150, 200) → enemy moves right and up
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 200), world: world)
        let vel2 = world.getComponent(type: VelocityComponent.self, for: enemy)!

        XCTAssertGreaterThan(vel1.linear.x, 0)
        XCTAssertLessThan(vel1.linear.y, 0, "Enemy should move down when target is below")
        XCTAssertGreaterThan(vel2.linear.x, 0)
        XCTAssertGreaterThan(vel2.linear.y, 0, "Enemy should move up when target is above")
    }

    // MARK: - Default Parameters

    func testDefaultInnerRadius() {
        let strategy = ShooterBasicStrategy()
        XCTAssertEqual(strategy.innerRadius, 100, accuracy: 0.001)
    }

    func testDefaultOuterRadius() {
        let strategy = ShooterBasicStrategy()
        XCTAssertEqual(strategy.outerRadius, 200, accuracy: 0.001)
    }

    func testDefaultMoveSpeed() {
        let strategy = ShooterBasicStrategy()
        XCTAssertEqual(strategy.moveSpeed, 60, accuracy: 0.001)
    }

    func testDefaultArcRange() {
        let strategy = ShooterBasicStrategy()
        XCTAssertEqual(strategy.arcRange, .pi / 3, accuracy: 0.001)
    }
}
