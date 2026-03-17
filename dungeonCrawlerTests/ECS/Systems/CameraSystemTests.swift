//
//  CameraSystemTests.swift
//  dungeonCrawler
//
//  Created by gerteck on 17/3/26.
//

import XCTest
@testable import dungeonCrawler

final class CameraSystemTests: XCTestCase {

    var world: World!
    var system: CameraSystem!
    var cameraEntity: Entity!

    override func setUp() {
        super.setUp()
        world        = World()
        system       = CameraSystem()
        cameraEntity = world.createEntity()
        world.addComponent(component: ViewportComponent(), to: cameraEntity)
    }

    override func tearDown() {
        system       = nil
        cameraEntity = nil
        world        = nil
        super.tearDown()
    }

    private func viewportPosition() -> SIMD2<Float> {
        world.getComponent(type: ViewportComponent.self, for: cameraEntity)?.position ?? .zero
    }

    func testNoFocusEntityDoesNotMoveCamera() {
        world.modifyComponent(type: ViewportComponent.self, for: cameraEntity) { $0.position = SIMD2(10, 20) }
        system.update(deltaTime: 0.016, world: world)
        let pos = viewportPosition()
        XCTAssertEqual(pos.x, 10, accuracy: 0.001)
        XCTAssertEqual(pos.y, 20, accuracy: 0.001)
    }

    func testEntityWithoutFocusComponentIgnored() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(100, 100)), to: entity)
        // No CameraFocusComponent
        system.update(deltaTime: 0.016, world: world)
        let pos = viewportPosition()
        XCTAssertEqual(pos.x, 0, accuracy: 0.001)
        XCTAssertEqual(pos.y, 0, accuracy: 0.001)
    }

    func testCameraMovesTowardTarget() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(100, 0)), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)

        system.update(deltaTime: 0.016, world: world)

        let pos = viewportPosition()
        XCTAssertGreaterThan(pos.x, 0)
        XCTAssertLessThan(pos.x, 100)
    }

    func testLookOffsetApplied() {
        // entity at origin, offset (30, -20) → camera should target (30, -20)
        system.smoothing = 10.0
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: .zero), to: entity)
        world.addComponent(component: CameraFocusComponent(lookOffset: SIMD2<Float>(30, -20)), to: entity)

        system.update(deltaTime: 1.0, world: world)

        let pos = viewportPosition()
        XCTAssertEqual(pos.x,  30.0, accuracy: 0.001)
        XCTAssertEqual(pos.y, -20.0, accuracy: 0.001)
    }

    func testMultipleFramesConverge() {
        system.smoothing = 8.0
        let target = SIMD2<Float>(200, 150)
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: target), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)

        for _ in 0..<120 {   // ~2 s at 60 fps
            system.update(deltaTime: 1.0 / 60.0, world: world)
        }

        let pos = viewportPosition()
        XCTAssertEqual(pos.x, target.x, accuracy: 0.5)
        XCTAssertEqual(pos.y, target.y, accuracy: 0.5)
    }
}
