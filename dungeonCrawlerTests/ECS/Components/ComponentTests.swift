//
//  ComponentTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler
 
final class ComponentTests: XCTestCase {
    
    var world: World!
    
    override func setUp() {
        super.setUp()
        world = World()
    }
    
    override func tearDown() {
        world = nil
        super.tearDown()
    }
    
    // MARK: - TransformComponent Tests
    
    func testTransformComponentDefaultInitialization() {
        let transform = TransformComponent()
        
        XCTAssertEqual(transform.position, SIMD2<Float>(0, 0))
        XCTAssertEqual(transform.rotation, 0)
        XCTAssertEqual(transform.scale, 1)
    }
    
    func testTransformComponentCustomInitialization() {
        let transform = TransformComponent(
            position: SIMD2<Float>(10, 20),
            rotation: 1.57,
            scale: 2.0
        )
        
        XCTAssertEqual(transform.position.x, 10)
        XCTAssertEqual(transform.position.y, 20)
        XCTAssertEqual(transform.rotation, 1.57, accuracy: 0.01)
        XCTAssertEqual(transform.scale, 2.0)
    }
    
    func testTransformComponentCGPointConversion() {
        let transform = TransformComponent(position: SIMD2<Float>(100, 200))
        let cgPoint = transform.cgPoint
        
        XCTAssertEqual(cgPoint.x, 100, accuracy: 0.01)
        XCTAssertEqual(cgPoint.y, 200, accuracy: 0.01)
    }
    
    func testTransformComponentNegativeValues() {
        let transform = TransformComponent(
            position: SIMD2<Float>(-50, -100),
            rotation: -3.14,
            scale: -1.0
        )
        
        XCTAssertEqual(transform.position.x, -50)
        XCTAssertEqual(transform.rotation, -3.14, accuracy: 0.01)
        XCTAssertEqual(transform.scale, -1.0)
    }
    
    // MARK: - VelocityComponent Tests
    
    func testVelocityComponentDefaultInitialization() {
        let velocity = VelocityComponent()
        
        XCTAssertEqual(velocity.linear, SIMD2<Float>(0, 0))
        XCTAssertEqual(velocity.angular, 0)
    }
    
    func testVelocityComponentCustomInitialization() {
        let velocity = VelocityComponent(
            linear: SIMD2<Float>(5, 10),
            angular: 0.5
        )
        
        XCTAssertEqual(velocity.linear.x, 5)
        XCTAssertEqual(velocity.linear.y, 10)
        XCTAssertEqual(velocity.angular, 0.5)
    }
    
    func testVelocityComponentNegativeValues() {
        let velocity = VelocityComponent(
            linear: SIMD2<Float>(-5, -10),
            angular: -0.5
        )
        
        XCTAssertEqual(velocity.linear.x, -5)
        XCTAssertEqual(velocity.angular, -0.5)
    }
    
    // MARK: - InputComponent Tests
    
    func testInputComponentDefaultInitialization() {
        let input = InputComponent()
        
        XCTAssertEqual(input.moveDirection, SIMD2<Float>(0, 0))
        XCTAssertEqual(input.aimDirection, SIMD2<Float>(0, 0))
        XCTAssertFalse(input.isShooting)
    }
    
    func testInputComponentCustomInitialization() {
        let input = InputComponent(
            moveDirection: SIMD2<Float>(1, 0),
            aimDirection: SIMD2<Float>(0, 1),
            isShooting: true
        )
        
        XCTAssertEqual(input.moveDirection, SIMD2<Float>(1, 0))
        XCTAssertEqual(input.aimDirection, SIMD2<Float>(0, 1))
        XCTAssertTrue(input.isShooting)
    }
    
    func testInputComponentNormalizedDirections() {
        let input = InputComponent(
            moveDirection: SIMD2<Float>(0.707, 0.707),
            aimDirection: SIMD2<Float>(-1, 0)
        )
        
        XCTAssertEqual(input.moveDirection.x, 0.707, accuracy: 0.001)
        XCTAssertEqual(input.aimDirection.x, -1)
    }
    
    // MARK: - SpriteComponent Tests
    
    func testSpriteComponentDefaultInitialization() {
        let sprite = SpriteComponent(content: .texture(name: "player"))
        
        if case .texture(let name) = sprite.content {
            XCTAssertEqual(name, "player")
        } else {
            XCTFail("Expected texture content")
        }
        
        XCTAssertEqual(sprite.tint, SIMD4<Float>(1, 1, 1, 1))
        XCTAssertEqual(sprite.layer, .entity)
        XCTAssertEqual(sprite.anchorPoint, SIMD2<Float>(0.5, 0.5))
    }
    
    func testSpriteComponentCustomTint() {
        let sprite = SpriteComponent(
            content: .texture(name: "enemy"),
            tint: SIMD4<Float>(1.0, 0.5, 0.5, 0.8)
        )
        
        if case .texture(let name) = sprite.content {
            XCTAssertEqual(name, "enemy")
        }
        XCTAssertEqual(sprite.tint.x, 1.0)
        XCTAssertEqual(sprite.tint.y, 0.5)
        XCTAssertEqual(sprite.tint.z, 0.5)
        XCTAssertEqual(sprite.tint.w, 0.8)
    }
    
    func testSpriteComponentRedTint() {
        let sprite = SpriteComponent(
            content: .texture(name: "damage_flash"),
            tint: SIMD4<Float>(1.0, 0.0, 0.0, 1.0)
        )
        
        XCTAssertEqual(sprite.tint.x, 1.0)
        XCTAssertEqual(sprite.tint.y, 0.0)
        XCTAssertEqual(sprite.tint.z, 0.0)
    }
    
    // MARK: - PlayerTagComponent Tests
    
    func testPlayerTagComponentInitialization() {
        let tag = PlayerTagComponent()
        
        // Just verify it can be created (it's a marker component with no data)
        XCTAssertNotNil(tag)
    }
    
    // MARK: - Component Integration Tests
    
    func testComponentsInECS() {
        let entity = world.createEntity()
        
        // Add all component types
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(10, 20)), to: entity)
        world.addComponent(component: VelocityComponent(linear: SIMD2<Float>(5, 5)), to: entity)
        world.addComponent(component: InputComponent(), to: entity)
        world.addComponent(component: SpriteComponent(content: .texture(name: "player")), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        
        // Verify all components exist
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: VelocityComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: entity))
        XCTAssertNotNil(world.getComponent(type: PlayerTagComponent.self, for: entity))
    }
    
    func testComponentValueSemantics() {
        // Components are value types (structs), so modifications create copies
        var transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        let transform2 = transform1
        
        transform1.position.x = 100
        
        XCTAssertEqual(transform1.position.x, 100)
        XCTAssertEqual(transform2.position.x, 10) // Should not have changed
    }
    
    func testComponentMutation() {
        let entity = world.createEntity()
        
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        
        world.modifyComponentIfExist(type: TransformComponent.self, for: entity) { transform in
            transform.position = SIMD2<Float>(100, 200)
            transform.scale = 2.0
        }
        
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform?.position.x, 100)
        XCTAssertEqual(transform?.scale, 2.0)
    }
}
 
