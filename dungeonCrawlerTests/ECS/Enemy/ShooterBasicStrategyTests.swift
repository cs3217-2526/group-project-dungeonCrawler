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
    var strategy: ShooterBasicStrategy!
    
    // Properties for tracked entities and components
    var enemy: Entity!
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var shooterComp: ShooterBasicComponent!

    override func setUp() {
        super.setUp()
        world = World()
        strategy = ShooterBasicStrategy()
        
        // Initialize components
        transform = TransformComponent(position: SIMD2<Float>(150, 0))
        velocity = VelocityComponent()
        shooterComp = ShooterBasicComponent()
        
        // Initialize main test entity
        enemy = world.createEntity()
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)
        // shooterComp is left out for tests that check lazy attachment,
        // or added manually via setTarget helper.
    }

    override func tearDown() {
        world = nil
        strategy = nil
        enemy = nil
        transform = nil
        velocity = nil
        shooterComp = nil
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
        shooterComp.targetAngle = angle
        shooterComp.targetRadius = radius
        world.addComponent(component: shooterComp, to: entity)
    }

    // MARK: - Lazy Component Attachment

    func testLazilyAttachesComponentOnFirstUpdate() {
        // Create fresh local tracking for this specific test
        let freshEnemy = makeEnemy(at: SIMD2(150, 0))
        let freshTransform = world.getComponent(type: TransformComponent.self, for: freshEnemy)!
        
        XCTAssertNil(world.getComponent(type: ShooterBasicComponent.self, for: freshEnemy))

        strategy.update(entity: freshEnemy, transform: freshTransform, playerPos: .zero, world: world)

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: freshEnemy))
    }

    func testComponentPersistsBetweenUpdates() {
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertNotNil(world.getComponent(type: ShooterBasicComponent.self, for: enemy))
    }

    // MARK: - First Update (no target yet)

    func testVelocityIsZeroOnFirstUpdate() {
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertEqual(velocity.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001)
    }

    func testTargetIsPickedOnFirstUpdate() {
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        XCTAssertNotNil(comp.targetAngle)
        XCTAssertNotNil(comp.targetRadius)
    }

    func testTargetRadiusWithinAnnulus() {
        let customStrategy = ShooterBasicStrategy(innerRadius: 100, outerRadius: 200)
        customStrategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: enemy)!
        let radius = comp.targetRadius!
        XCTAssertGreaterThanOrEqual(radius, 100)
        XCTAssertLessThanOrEqual(radius, 200)
    }

    // MARK: - Movement Toward Target

    func testVelocityPointsTowardTarget() {
        // Use class properties for cleaner assertions
        transform.position = SIMD2(0, 0)
        setTarget(on: enemy, angle: 0, radius: 150)
        
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertGreaterThan(velocity.linear.x, 0, "Velocity x should be positive when target is to the right")
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.01)
    }

    func testVelocityMagnitudeEqualsMoveSpeed() {
        let moveSpeed: Float = 75
        let customStrategy = ShooterBasicStrategy(innerRadius: 100, outerRadius: 200, moveSpeed: moveSpeed)
        
        setTarget(on: enemy, angle: .pi / 4, radius: 150)
        customStrategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertEqual(simd_length(velocity.linear), moveSpeed, accuracy: 0.01)
    }

    // MARK: - Arrival Behaviour

    func testVelocityZeroOnArrival() {
        // Enemy at (150, 0), target world pos = (150, 0)
        setTarget(on: enemy, angle: 0, radius: 150)
        strategy.update(entity: enemy, transform: transform, playerPos: .zero, world: world)

        XCTAssertEqual(velocity.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.001)
    }

    // MARK: - Target Tracks Player

    func testTargetFollowsPlayerMovement() {
        // Update the main tracked enemy position
        transform.position = SIMD2(0, 50)
        setTarget(on: enemy, angle: 0, radius: 150)

        // Player at (0, 0) -> target world pos (150, 0) -> enemy moves right and down
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 0), world: world)
        let vx1 = velocity.linear.x
        let vy1 = velocity.linear.y

        // Player at (0, 200) -> target world pos (150, 200) -> enemy moves right and up
        strategy.update(entity: enemy, transform: transform, playerPos: SIMD2(0, 200), world: world)
        let vx2 = velocity.linear.x
        let vy2 = velocity.linear.y

        XCTAssertGreaterThan(vx1, 0)
        XCTAssertLessThan(vy1, 0, "Enemy should move down when target is below")
        XCTAssertGreaterThan(vx2, 0)
        XCTAssertGreaterThan(vy2, 0, "Enemy should move up when target is above")
    }

    // MARK: - Default Parameters

    func testDefaultInnerRadius() {
        XCTAssertEqual(strategy.innerRadius, 100, accuracy: 0.001)
    }

    func testDefaultOuterRadius() {
        XCTAssertEqual(strategy.outerRadius, 200, accuracy: 0.001)
    }

    func testDefaultMoveSpeed() {
        XCTAssertEqual(strategy.moveSpeed, 60, accuracy: 0.001)
    }

    func testDefaultArcRange() {
        XCTAssertEqual(strategy.arcRange, .pi / 3, accuracy: 0.001)
    }
}
