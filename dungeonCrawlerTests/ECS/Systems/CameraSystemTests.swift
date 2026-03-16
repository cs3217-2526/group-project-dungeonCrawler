// 
//  CameraSystemTests.swift
//  dungeonCrawler
//
//  Created by gerteck on 17/3/26.
//


import XCTest
import SpriteKit
@testable import dungeonCrawler

@MainActor
final class CameraSystemTests: XCTestCase {

    var world: World!
    var cameraNode: SKCameraNode!
    var system: CameraSystem!

    override func setUp() {
        super.setUp()
        world      = World()
        cameraNode = SKCameraNode()
        system     = CameraSystem(cameraNode: cameraNode)
    }

    override func tearDown() {
        system     = nil
        cameraNode = nil
        world      = nil
        super.tearDown()
    }

    func testNoFocusEntityDoesNotMoveCamera() {
        cameraNode.position = CGPoint(x: 10, y: 20)
        system.update(deltaTime: 0.016, world: world)
        XCTAssertEqual(cameraNode.position.x, 10, accuracy: 0.001)
        XCTAssertEqual(cameraNode.position.y, 20, accuracy: 0.001)
    }

    func testEntityWithoutFocusComponentIgnored() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(100, 100)), to: entity)
        // No CameraFocusComponent
        cameraNode.position = .zero
        system.update(deltaTime: 0.016, world: world)
        XCTAssertEqual(cameraNode.position.x, 0, accuracy: 0.001)
        XCTAssertEqual(cameraNode.position.y, 0, accuracy: 0.001)
    }

    // MARK: - Lerp smoothing behaviour
    func testCameraMovesTowardTarget() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(100, 0)), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)
        cameraNode.position = .zero

        system.update(deltaTime: 0.016, world: world)

        XCTAssertGreaterThan(cameraNode.position.x, 0)
        XCTAssertLessThan(cameraNode.position.x, 100)
    }

    func testLerpMathExact() {
        // smoothing=1, deltaTime=0.5 → t = min(0.5, 1) = 0.5
        // camera starts at 0, target at 100 → next = 0 + (100−0)*0.5 = 50
        system.smoothing = 1.0
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(100, 0)), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)
        cameraNode.position = .zero

        system.update(deltaTime: 0.5, world: world)

        XCTAssertEqual(Float(cameraNode.position.x), 50.0, accuracy: 0.001)
        XCTAssertEqual(Float(cameraNode.position.y), 0.0,  accuracy: 0.001)
    }

    func testLerpFactorClampedToOne() {
        // smoothing=10, deltaTime=1.0 → t = min(10, 1) = 1 → snap instantly
        system.smoothing = 10.0
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(50, 75)), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(Float(cameraNode.position.x), 50.0, accuracy: 0.001)
        XCTAssertEqual(Float(cameraNode.position.y), 75.0, accuracy: 0.001)
    }

    func testLookOffsetApplied() {
        // entity at origin, offset (30, -20) → camera should target (30, -20)
        system.smoothing = 10.0  // snap
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: .zero), to: entity)
        world.addComponent(component: CameraFocusComponent(lookOffset: SIMD2<Float>(30, -20)), to: entity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(Float(cameraNode.position.x),  30.0, accuracy: 0.001)
        XCTAssertEqual(Float(cameraNode.position.y), -20.0, accuracy: 0.001)
    }

    func testMultipleFramesConverge() {
        system.smoothing = 8.0
        let target = SIMD2<Float>(200, 150)
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: target), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)
        cameraNode.position = .zero

        for _ in 0..<120 {   // ~2 s at 60 fps
            system.update(deltaTime: 1.0 / 60.0, world: world)
        }

        XCTAssertEqual(Float(cameraNode.position.x), target.x, accuracy: 0.5)
        XCTAssertEqual(Float(cameraNode.position.y), target.y, accuracy: 0.5)
    }
}
