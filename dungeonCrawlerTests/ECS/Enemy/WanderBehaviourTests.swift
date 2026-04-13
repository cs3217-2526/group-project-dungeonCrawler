//
//  WanderBehaviourTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 9/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class WanderBehaviourTests: XCTestCase {

    // MARK: - Properties
    var world: World!
    var enemy: Entity!

    // Behaviours
    var behaviour: WanderBehaviour!
    var customRadiusBehaviour: WanderBehaviour!
    var customSpeedBehaviour: WanderBehaviour!

    // Components
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var wanderTargetComp: WanderTargetComponent!

    // Context
    var context: BehaviourContext!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()

        // 1. Core ECS
        world = World()
        enemy = world.createEntity()

        // 2. Behaviours
        behaviour = WanderBehaviour()
        customRadiusBehaviour = WanderBehaviour(wanderRadius: 200)
        customSpeedBehaviour = WanderBehaviour(wanderSpeed: 60)

        // 3. Components
        transform = TransformComponent(position: .zero)
        velocity = VelocityComponent()
        wanderTargetComp = WanderTargetComponent()

        // 4. Initial World State
        world.addComponent(component: transform, to: enemy)
        world.addComponent(component: velocity, to: enemy)

        // 5. Default Context
        context = BehaviourContext(entity: enemy, playerPos: SIMD2(999, 999), transform: transform, world: world)
    }

    override func tearDown() {
        // Explicitly nil everything to prevent background deallocation SIGABRTs
        context = nil
        wanderTargetComp = nil
        velocity = nil
        transform = nil

        customSpeedBehaviour = nil
        customRadiusBehaviour = nil
        behaviour = nil

        enemy = nil
        world = nil

        super.tearDown()
    }

    // MARK: - Default initialisation

    func testDefaultWanderRadius() {
        XCTAssertEqual(WanderBehaviour().wanderRadius, 100, accuracy: 0.001)
    }

    func testDefaultWanderSpeed() {
        XCTAssertEqual(WanderBehaviour().wanderSpeed, 40, accuracy: 0.001)
    }

    // MARK: - Lazy WanderTargetComponent

    func testWanderTargetComponentAbsentBeforeFirstUpdate() {
        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))
    }

    func testWanderTargetComponentAddedOnFirstUpdate() {
        behaviour.update(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))
    }

    // MARK: - Deactivation cleanup
    // TODO: fix
//    func testWanderTargetComponentRemovedOnDeactivate() {
//        behaviour.update(entity: enemy, context: context)
//
//        // Capture reference to prevent deallocation crash during removal
//        let target = world.getComponent(type: WanderTargetComponent.self, for: enemy)
//        XCTAssertNotNil(target)
//
//        behaviour.onDeactivate(entity: enemy, context: context)
//        XCTAssertNil(world.getComponent(type: WanderTargetComponent.self, for: enemy))
//    }

    // MARK: - Update behaviour

    func testUpdateProducesNonZeroVelocity() {
        behaviour.update(entity: enemy, context: context)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertGreaterThan(simd_length(vel.linear), 0)
    }

    func testVelocityMagnitudeEqualsWanderSpeed() {
        let speed: Float = 50
        let specificBehaviour = WanderBehaviour(wanderSpeed: speed)

        specificBehaviour.update(entity: enemy, context: context)

        let vel = world.getComponent(type: VelocityComponent.self, for: enemy)!
        XCTAssertEqual(simd_length(vel.linear), speed, accuracy: 0.01)
    }

    func testWanderTargetMinRadiusFloor() {
        behaviour.update(entity: enemy, context: context)

        let target = world.getComponent(type: WanderTargetComponent.self, for: enemy)?.target
        XCTAssertNotNil(target)
        XCTAssertGreaterThan(simd_length(target! - transform.position), 0)
    }

    // MARK: - Target persistence

    func testWanderTargetPersistedBetweenUpdates() throws {
        behaviour.update(entity: enemy, context: context)
        let target1 = world.getComponent(type: WanderTargetComponent.self, for: enemy)!.target

        behaviour.update(entity: enemy, context: context)
        let target2 = world.getComponent(type: WanderTargetComponent.self, for: enemy)!.target

        XCTAssertEqual(target1!.x, target2!.x, accuracy: 0.001)
        XCTAssertEqual(target1!.y, target2!.y, accuracy: 0.001)
    }

    func testVelocityDirectionIsConsistentBeforeArrival() {
        behaviour.update(entity: enemy, context: context)
        let vel1 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        behaviour.update(entity: enemy, context: context)
        let vel2 = world.getComponent(type: VelocityComponent.self, for: enemy)!.linear

        XCTAssertEqual(vel1.x, vel2.x, accuracy: 0.001)
        XCTAssertEqual(vel1.y, vel2.y, accuracy: 0.001)
    }
}
