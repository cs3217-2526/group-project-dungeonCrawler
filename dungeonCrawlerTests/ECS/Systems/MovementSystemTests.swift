//
//  MovementSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler
 
final class MovementSystemTests: XCTestCase {
    
    var world: World!
    var system: MovementSystem!
    
    override func setUp() {
        super.setUp()
        world = World()
        system = MovementSystem()
    }
    
    override func tearDown() {
        system = nil
        world = nil
        super.tearDown()
    }
    
    // MARK: - Basic Movement
    
    func testBasicMovement() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.position.x, 10, accuracy: 0.01) // 100 speed * 0.1 dt * 1 direction
        XCTAssertEqual(transform!.position.y, 0, accuracy: 0.01)
    }
    
    func testMovementInAllDirections() {
        let speed: Float = 100
        let directions: [SIMD2<Float>] = [
            SIMD2<Float>(1, 0),   // Right
            SIMD2<Float>(-1, 0),  // Left
            SIMD2<Float>(0, 1),   // Up
            SIMD2<Float>(0, -1),  // Down
            SIMD2<Float>(1, 1),   // Diagonal
        ]

        for direction in directions {
            let entity = world.createEntity()
            world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
            world.addComponent(component: VelocityComponent(), to: entity)
            world.addComponent(component: InputComponent(moveDirection: direction), to: entity)
            world.addComponent(component: MoveSpeedComponent(base: speed), to: entity)

            system.update(deltaTime: 0.1, world: world)

            let transform = world.getComponent(type: TransformComponent.self, for: entity)
            XCTAssertNotNil(transform)

            // Position should have moved in the direction
            let expectedDisplacement = direction * speed * 0.1
            XCTAssertEqual(transform!.position.x, expectedDisplacement.x, accuracy: 0.01)
            XCTAssertEqual(transform!.position.y, expectedDisplacement.y, accuracy: 0.01)
        }
    }
    
    func testNoMovementWhenDirectionIsZero() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(10, 20)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform!.position.x, 10, accuracy: 0.01)
        XCTAssertEqual(transform!.position.y, 20, accuracy: 0.01)
    }
    
    // MARK: - Velocity Integration
    
    func testVelocityIsSetFromInput() {
        let speed: Float = 100
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: speed), to: entity)

        system.update(deltaTime: 0.1, world: world)

        let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
        XCTAssertNotNil(velocity)
        XCTAssertEqual(velocity!.linear.x, speed, accuracy: 0.01)
        XCTAssertEqual(velocity!.linear.y, 0, accuracy: 0.01)
    }
    
    func testDifferentMoveSpeed() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 200), to: entity)

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform!.position.x, 20, accuracy: 0.01) // 200 speed * 0.1 dt
    }
    
    // MARK: - Time Step Variations
    
    func testDifferentDeltaTimes() {
        let speed: Float = 100
        let deltaTimes: [Double] = [0.016, 0.033, 0.1, 1.0]

        for dt in deltaTimes {
            let entity = world.createEntity()
            world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
            world.addComponent(component: VelocityComponent(), to: entity)
            world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
            world.addComponent(component: MoveSpeedComponent(base: speed), to: entity)

            system.update(deltaTime: dt, world: world)

            let transform = world.getComponent(type: TransformComponent.self, for: entity)
            let expectedDistance = Float(dt) * speed
            XCTAssertEqual(transform!.position.x, expectedDistance, accuracy: 0.01)
        }
    }
    
    func testAccumulatedMovementOverMultipleFrames() {
        let speed: Float = 100
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: speed), to: entity)

        // Simulate 10 frames
        for _ in 0..<10 {
            system.update(deltaTime: 0.016, world: world)
        }

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        let expectedDistance = Float(0.016 * 10) * speed
        XCTAssertEqual(transform!.position.x, expectedDistance, accuracy: 0.1)
    }
    
    // MARK: - World Bounds
    
    func testWorldBoundsClampingMinX() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(-400, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(-1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        system.worldBounds = (minX: -500, maxX: 500, minY: -500, maxY: 500)
        system.update(deltaTime: 1.0, world: world) // Move far left

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertGreaterThanOrEqual(transform!.position.x, system.worldBounds.minX)
    }
    
    func testWorldBoundsClampingMaxX() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(400, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        system.worldBounds = (minX: -500, maxX: 500, minY: -500, maxY: 500)
        system.update(deltaTime: 1.0, world: world) // Move far right

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertLessThanOrEqual(transform!.position.x, system.worldBounds.maxX)
    }
    
    func testWorldBoundsClampingY() {
        // Test min Y
        let entity1 = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, -400)), to: entity1)
        world.addComponent(component: VelocityComponent(), to: entity1)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(0, -1)), to: entity1)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity1)

        system.worldBounds = (minX: -500, maxX: 500, minY: -500, maxY: 500)
        system.update(deltaTime: 1.0, world: world)

        let transform1 = world.getComponent(type: TransformComponent.self, for: entity1)
        XCTAssertGreaterThanOrEqual(transform1!.position.y, system.worldBounds.minY)

        // Test max Y
        let entity2 = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 400)), to: entity2)
        world.addComponent(component: VelocityComponent(), to: entity2)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(0, 1)), to: entity2)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity2)

        system.update(deltaTime: 1.0, world: world)

        let transform2 = world.getComponent(type: TransformComponent.self, for: entity2)
        XCTAssertLessThanOrEqual(transform2!.position.y, system.worldBounds.maxY)
    }
    
    func testMovementWithinBounds() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 1)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        system.worldBounds = (minX: -500, maxX: 500, minY: -500, maxY: 500)
        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertGreaterThanOrEqual(transform!.position.x, system.worldBounds.minX)
        XCTAssertLessThanOrEqual(transform!.position.x, system.worldBounds.maxX)
        XCTAssertGreaterThanOrEqual(transform!.position.y, system.worldBounds.minY)
        XCTAssertLessThanOrEqual(transform!.position.y, system.worldBounds.maxY)
    }
    
    // MARK: - Missing Components
    
    func testEntityWithoutTransform() {
        let entity = world.createEntity()
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        
        // Should not crash
        system.update(deltaTime: 0.1, world: world)
    }
    
    func testEntityWithoutVelocity() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        
        // Should not crash, position should not change
        system.update(deltaTime: 0.1, world: world)
        
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform!.position.x, 0, accuracy: 0.01)
    }
    
    func testEntityWithoutInput() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        
        // Should not crash, position should not change
        system.update(deltaTime: 0.1, world: world)
        
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform!.position.x, 0, accuracy: 0.01)
    }
    
    // MARK: - Multiple Entities
    
    func testMultipleEntitiesMoving() {
        let entity1 = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity1)
        world.addComponent(component: VelocityComponent(), to: entity1)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity1)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity1)

        let entity2 = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity2)
        world.addComponent(component: VelocityComponent(), to: entity2)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(0, 1)), to: entity2)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity2)

        system.update(deltaTime: 0.1, world: world)

        let transform1 = world.getComponent(type: TransformComponent.self, for: entity1)
        let transform2 = world.getComponent(type: TransformComponent.self, for: entity2)

        XCTAssertEqual(transform1!.position.x, 10, accuracy: 0.01)
        XCTAssertEqual(transform1!.position.y, 0, accuracy: 0.01)
        XCTAssertEqual(transform2!.position.x, 0, accuracy: 0.01)
        XCTAssertEqual(transform2!.position.y, 10, accuracy: 0.01)
    }
    
    func testNoEntitiesDoesNotCrash() {
        // Should not crash with no entities
        system.update(deltaTime: 0.1, world: world)
    }

    func testEntityWithoutMoveSpeedSkipped() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(5, 5)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        // No MoveSpeedComponent — entity should be skipped

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform!.position.x, 5, accuracy: 0.01)
        XCTAssertEqual(transform!.position.y, 5, accuracy: 0.01)
    }
}
