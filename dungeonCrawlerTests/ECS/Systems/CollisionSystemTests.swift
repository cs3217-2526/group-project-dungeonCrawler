//
//  CollisionSystemTests.swift
//  dungeonCrawler
//
//  Created by Yu Letian on 16/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

final class CollisionSystemTests: XCTestCase {

    var world: World!
    var collisionSystem: CollisionSystem!

    override func setUp() {
        super.setUp()
        world = World()
        collisionSystem = CollisionSystem()
    }


    // Creates an entity with the components required for collision testing.
    // TODO: add stats when ready
    private func makeCollidableEntity(at position: SIMD2<Float>, size: SIMD2<Float>, rotation: Float = 0) -> Entity {
        let entity = world.createEntity()
        try! world.addComponent(component: TransformComponent(position: position, rotation: rotation, scale: 1), to: entity)
        try! world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        return entity
    }

    // no collision when entities do not overlap

    func testNoCollisionWhenSeparated() {
        let box = SIMD2<Float>(10, 10)
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(10, 0), scale: 1) // 10 apart, 5 each side = touching exactly
        let boxComp = CollisionBoxComponent(size: box)

        // Exactly touching (distance == sum of half-widths) is NOT a collision.
        XCTAssertFalse(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxComp,
            transformB: transformB, boxB: boxComp
        ))
    }


    func testNoCollisionWhenClearlyApart() {
        let box = SIMD2<Float>(10, 10)
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(100, 0), scale: 1)
        let boxComp = CollisionBoxComponent(size: box)

        XCTAssertFalse(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxComp,
            transformB: transformB, boxB: boxComp
        ))
    }
    
    // collision detected when entities overlap

    func testCollisionWhenOverlapping() {
        let box = SIMD2<Float>(10, 10)
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(5, 0), scale: 1) // 5 apart, boxes overlap by 5
        let boxComp = CollisionBoxComponent(size: box)

        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxComp,
            transformB: transformB, boxB: boxComp
        ))
    }
    
    func testCollisionWithDifferentBoxSize() {
        // A at (0,0) size (10,10): right edge at x=5
        // B at (10,0) size (20,20): left edge at x=0, overlap of 5
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(10, 0), scale: 1)
        let boxCompA = CollisionBoxComponent(size: SIMD2<Float>(10, 10))
        let boxCompB = CollisionBoxComponent(size: SIMD2<Float>(20, 20))

        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxCompA,
            transformB: transformB, boxB: boxCompB
        ))
    }

    func testCollisionWithRotation() {
        // A at (0,0) size (10,10): right edge at x=5
        // B at (10,0) size (20,20) rotated 45 degrees: left edge extends to x=-5, overlap of 10
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), rotation: 0, scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(10, 0), rotation: .pi / 4, scale: 1)
        let boxCompA = CollisionBoxComponent(size: SIMD2<Float>(10, 10))
        let boxCompB = CollisionBoxComponent(size: SIMD2<Float>(20, 20))

        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxCompA,
            transformB: transformB, boxB: boxCompB
        ))
    }
}
