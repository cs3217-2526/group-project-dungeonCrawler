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
    var transformDefault: TransformComponent!
    var transformCustom: TransformComponent!
    var transform1: TransformComponent!
    
    var velocityDefault: VelocityComponent!
    var velocityCustom: VelocityComponent!
    var velocity1: VelocityComponent!
    
    var inputDefault: InputComponent!
    var inputCustom: InputComponent!
    
    var spriteDefault: SpriteComponent!
    var spriteCustom: SpriteComponent!
    
    var playerTag: PlayerTagComponent!
    
    
    override func setUp() {
        super.setUp()
        transformDefault = TransformComponent()
        transformCustom = TransformComponent(
            position: SIMD2<Float>(10, 20),
            rotation: 1.57,
            scale: 2.0
        )
        transform1 = TransformComponent(position: SIMD2<Float>(10, 20))
        
        velocityDefault = VelocityComponent()
        velocityCustom = VelocityComponent(
            linear: SIMD2<Float>(5, 10),
            angular: 0.5
        )
        
        inputDefault = InputComponent()
        inputCustom = InputComponent(
            moveDirection: SIMD2<Float>(1, 0),
            aimDirection: SIMD2<Float>(0, 1),
            isShooting: true
        )
        
        spriteDefault = SpriteComponent(content: .texture(name: "player"))
        spriteCustom = SpriteComponent(
            content: .texture(name: "enemy"),
            tint: SIMD4<Float>(1.0, 0.5, 0.5, 0.8)
        )
        
        playerTag = PlayerTagComponent()
        
        world = World()
    }
    
    override func tearDown() {
        world = nil
        transformDefault = nil
        transformCustom = nil
        transform1 = nil
        velocityDefault = nil
        velocityCustom = nil
        velocity1 = nil
        inputDefault = nil
        inputCustom = nil
        spriteDefault = nil
        spriteCustom = nil
        playerTag = nil
        super.tearDown()
    }
    
    // MARK: - TransformComponent Tests
    
    func testTransformComponentDefaultInitialization() {
        XCTAssertEqual(transformDefault.position, SIMD2<Float>(0, 0))
        XCTAssertEqual(transformDefault.rotation, 0)
        XCTAssertEqual(transformDefault.scale, 1)
    }
    
    func testTransformComponentCustomInitialization() {
        XCTAssertEqual(transformCustom.position.x, 10)
        XCTAssertEqual(transformCustom.position.y, 20)
        XCTAssertEqual(transformCustom.rotation, 1.57, accuracy: 0.01)
        XCTAssertEqual(transformCustom.scale, 2.0)
    }
    
    func testTransformComponentCGPointConversion() {
        let cgPoint = transform1.cgPoint
        
        XCTAssertEqual(cgPoint.x, 10, accuracy: 0.01)
        XCTAssertEqual(cgPoint.y, 20, accuracy: 0.01)
    }
    
    // MARK: - VelocityComponent Tests
    
    func testVelocityComponentDefaultInitialization() {
        XCTAssertEqual(velocityDefault.linear, SIMD2<Float>(0, 0))
        XCTAssertEqual(velocityDefault.angular, 0)
    }
    
    func testVelocityComponentCustomInitialization() {
        XCTAssertEqual(velocityCustom.linear.x, 5)
        XCTAssertEqual(velocityCustom.linear.y, 10)
        XCTAssertEqual(velocityCustom.angular, 0.5)
    }
    
    // MARK: - InputComponent Tests
    
    func testInputComponentDefaultInitialization() {
        XCTAssertEqual(inputDefault.moveDirection, SIMD2<Float>(0, 0))
        XCTAssertEqual(inputDefault.aimDirection, SIMD2<Float>(0, 0))
        XCTAssertFalse(inputDefault.isShooting)
    }
    
    func testInputComponentCustomInitialization() {
        XCTAssertEqual(inputCustom.moveDirection, SIMD2<Float>(1, 0))
        XCTAssertEqual(inputCustom.aimDirection, SIMD2<Float>(0, 1))
        XCTAssertTrue(inputCustom.isShooting)
    }
    
    // MARK: - SpriteComponent Tests
    
    func testSpriteComponentDefaultInitialization() {
        if case .texture(let name) = spriteDefault.content {
            XCTAssertEqual(name, "player")
        } else {
            XCTFail("Expected texture content")
        }
        
        XCTAssertEqual(spriteDefault.tint, SIMD4<Float>(1, 1, 1, 1))
        XCTAssertEqual(spriteDefault.layer, .entity)
        XCTAssertEqual(spriteDefault.anchorPoint, SIMD2<Float>(0.5, 0.5))
    }
    
    func testSpriteComponentCustomTint() {
        if case .texture(let name) = spriteCustom.content {
            XCTAssertEqual(name, "enemy")
        }
        XCTAssertEqual(spriteCustom.tint.x, 1.0)
        XCTAssertEqual(spriteCustom.tint.y, 0.5)
        XCTAssertEqual(spriteCustom.tint.z, 0.5)
        XCTAssertEqual(spriteCustom.tint.w, 0.8)
    }
    
    // MARK: - PlayerTagComponent Tests
    
    func testPlayerTagComponentInitialization() {
        XCTAssertNotNil(playerTag)
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
    
    func testComponentMutation() {
        let entity = world.createEntity()
        
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        
        if let transform = world.getComponent(type: TransformComponent.self, for: entity) {
            transform.position = SIMD2<Float>(100, 200)
            transform.scale = 2.0
        }
        
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertEqual(transform?.position.x, 100)
        XCTAssertEqual(transform?.scale, 2.0)
    }
}
 
