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

    // MARK: - Helpers

    /// Creates a room entity with the given bounds and returns its roomID.
    private func makeRoom(bounds: RoomBounds) -> UUID {
        let roomEntity = world.createEntity()
        let meta = RoomMetadataComponent(bounds: bounds)
        world.addComponent(component: meta, to: roomEntity)
        return meta.roomID
    }

    /// Attaches the enemy to a room so context.roomBounds resolves.
    private func joinRoom(roomID: UUID) {
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: enemy)
    }

    // MARK: - Default initialisation

    func testDefaultWanderRadius() {
        XCTAssertEqual(WanderBehaviour().wanderRadius, 100, accuracy: 0.001)
    }

    func testDefaultWanderSpeed() {
        XCTAssertEqual(WanderBehaviour().wanderSpeed, 40, accuracy: 0.001)
    }

    func testDefaultWallMargin() {
        XCTAssertEqual(WanderBehaviour().wallMargin, 40, accuracy: 0.001)
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

    // MARK: - Room bounds: target stays inside safe area

//    func testWanderTargetInsideRoomSafeAreaWhenRoomIsPresent() {
//        let roomBounds = RoomBounds(center: .zero, size: SIMD2(600, 600))
//        let roomID = makeRoom(bounds: roomBounds)
//        joinRoom(roomID: roomID)
//
//        let safeArea = roomBounds.inset(by: behaviour.wallMargin)
//
//        // Run several updates to increase coverage over random candidates
//        for _ in 0..<20 {
//            // Reset target each iteration so a new candidate is chosen
//            world.removeComponent(type: WanderTargetComponent.self, from: enemy)
//            behaviour.update(entity: enemy, context: context)
//
//            let target = world.getComponent(type: WanderTargetComponent.self, for: enemy)?.target
//            if let t = target {
//                XCTAssertTrue(safeArea.contains(t),
//                              "Target \(t) is outside safe area \(safeArea)")
//            }
//        }
//    }

//    func testWanderTargetPicksValidPointWhenEnemyNearWall() {
//        // Place enemy near the right wall — most random directions lead outside
//        let roomBounds = RoomBounds(center: .zero, size: SIMD2(600, 600))
//        let roomID = makeRoom(bounds: roomBounds)
//        joinRoom(roomID: roomID)
//
//        let nearWallPos = SIMD2<Float>(roomBounds.maxX - 10, roomBounds.center.y)
//        let nearWallTransform = TransformComponent(position: nearWallPos)
//        world.addComponent(component: nearWallTransform, to: enemy)
//        let nearWallContext = BehaviourContext(entity: enemy, playerPos: SIMD2(999, 999),
//                                               transform: nearWallTransform, world: world)
//
//        let safeArea = roomBounds.inset(by: behaviour.wallMargin)
//
//        for _ in 0..<10 {
//            world.removeComponent(type: WanderTargetComponent.self, from: enemy)
//            behaviour.update(entity: enemy, context: nearWallContext)
//
//            let target = world.getComponent(type: WanderTargetComponent.self, for: enemy)?.target
//            if let t = target {
//                XCTAssertTrue(safeArea.contains(t),
//                              "Near-wall target \(t) is outside safe area \(safeArea)")
//            }
//        }
//    }

    func testWanderBehaviourWithoutRoomMembershipStillProducesTarget() {
        // No RoomMemberComponent → roomBounds is nil → unconstrained fallback
        behaviour.update(entity: enemy, context: context)
        XCTAssertNotNil(world.getComponent(type: WanderTargetComponent.self, for: enemy)?.target,
                        "Should still pick a target when no room bounds are available")
    }
}
