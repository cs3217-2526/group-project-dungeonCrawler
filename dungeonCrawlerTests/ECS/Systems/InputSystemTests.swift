//
//  InputSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class InputSystemTests: XCTestCase {

    var world: World!
    var commandQueues: CommandQueues!
    var system: InputSystem!

    override func setUp() {
        super.setUp()
        world = World()
        commandQueues = CommandQueues()
        commandQueues.register(MoveCommand.self)
        commandQueues.register(AimCommand.self)
        commandQueues.register(FireCommand.self)
        commandQueues.register(DropWeaponCommand.self)
        commandQueues.register(PickupCommand.self)
        system = InputSystem(commandQueues: commandQueues)
    }

    override func tearDown() {
        system = nil
        commandQueues = nil
        world = nil
        super.tearDown()
    }

    // MARK: - Basic Input Propagation

    func testMoveDirectionPropagation() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 0)))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertNotNil(input)
        XCTAssertEqual(input!.moveDirection.x, 1)
        XCTAssertEqual(input!.moveDirection.y, 0)
    }

    func testAimDirectionPropagation() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(AimCommand(id: UUID(), rawAimVector: SIMD2<Float>(0, 1)))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertNotNil(input)
        XCTAssertEqual(input!.aimDirection.x, 0)
        XCTAssertEqual(input!.aimDirection.y, 1)
    }

    func testShootPressedPropagation() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(FireCommand(id: UUID(), shooting: true))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertNotNil(input)
        XCTAssertTrue(input!.isShooting)
    }

    func testAllInputsPropagatedTogether() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 1)))
        commandQueues.push(AimCommand(id: UUID(), rawAimVector: SIMD2<Float>(-1, 0)))
        commandQueues.push(FireCommand(id: UUID(), shooting: true))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection, SIMD2<Float>(1, 1))
        XCTAssertEqual(input!.aimDirection, SIMD2<Float>(-1, 0))
        XCTAssertTrue(input!.isShooting)
    }

    // MARK: - Multiple Entities

    func testMultipleEntitiesReceiveSameInput() {
        let entity1 = world.createEntity()
        let entity2 = world.createEntity()
        let entity3 = world.createEntity()

        world.addComponent(component: InputComponent(), to: entity1)
        world.addComponent(component: InputComponent(), to: entity2)
        world.addComponent(component: InputComponent(), to: entity3)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(0.5, -0.5)))

        system.update(deltaTime: 0.016, world: world)

        let input1 = world.getComponent(type: InputComponent.self, for: entity1)
        let input2 = world.getComponent(type: InputComponent.self, for: entity2)
        let input3 = world.getComponent(type: InputComponent.self, for: entity3)

        XCTAssertEqual(input1!.moveDirection, SIMD2<Float>(0.5, -0.5))
        XCTAssertEqual(input2!.moveDirection, SIMD2<Float>(0.5, -0.5))
        XCTAssertEqual(input3!.moveDirection, SIMD2<Float>(0.5, -0.5))
    }

    func testEntityWithoutInputComponentIgnored() {
        let entityWithInput = world.createEntity()
        let entityWithoutInput = world.createEntity()

        world.addComponent(component: InputComponent(), to: entityWithInput)
        world.addComponent(component: TransformComponent(), to: entityWithoutInput)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 0)))

        // Should not crash
        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entityWithInput)
        XCTAssertNotNil(input)
        XCTAssertEqual(input!.moveDirection.x, 1)

        // Entity without input component should not have gained one
        let noInput = world.getComponent(type: InputComponent.self, for: entityWithoutInput)
        XCTAssertNil(noInput)
    }

    // MARK: - Input Changes Over Time

    func testInputChangesAcrossFrames() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        // Frame 1: Moving right
        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 0)))
        system.update(deltaTime: 0.016, world: world)

        var input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection.x, 1)

        // Frame 2: Moving left
        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(-1, 0)))
        system.update(deltaTime: 0.016, world: world)

        input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection.x, -1)

        // Frame 3: No movement
        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(0, 0)))
        system.update(deltaTime: 0.016, world: world)

        input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection.x, 0)
    }

    func testShootButtonToggle() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        // Frame 1: Not shooting
        commandQueues.push(FireCommand(id: UUID(), shooting: false))
        system.update(deltaTime: 0.016, world: world)

        var input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertFalse(input!.isShooting)

        // Frame 2: Start shooting
        commandQueues.push(FireCommand(id: UUID(), shooting: true))
        system.update(deltaTime: 0.016, world: world)

        input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertTrue(input!.isShooting)

        // Frame 3: Stop shooting
        commandQueues.push(FireCommand(id: UUID(), shooting: false))
        system.update(deltaTime: 0.016, world: world)

        input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertFalse(input!.isShooting)
    }

    // MARK: - Edge Cases

    func testZeroInputVectors() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(0, 0)))
        commandQueues.push(AimCommand(id: UUID(), rawAimVector: SIMD2<Float>(0, 0)))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection, SIMD2<Float>(0, 0))
        XCTAssertEqual(input!.aimDirection, SIMD2<Float>(0, 0))
    }

    func testLargeInputValues() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1000, 1000)))
        commandQueues.push(AimCommand(id: UUID(), rawAimVector: SIMD2<Float>(-1000, -1000)))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection.x, 1000)
        XCTAssertEqual(input!.aimDirection.x, -1000)
    }

    func testNegativeInputValues() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(-1, -1)))
        commandQueues.push(AimCommand(id: UUID(), rawAimVector: SIMD2<Float>(-0.5, -0.5)))

        system.update(deltaTime: 0.016, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input!.moveDirection, SIMD2<Float>(-1, -1))
        XCTAssertEqual(input!.aimDirection, SIMD2<Float>(-0.5, -0.5))
    }

    func testNoEntitiesDoesNotCrash() {
        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 1)))

        // Should not crash with no entities
        system.update(deltaTime: 0.016, world: world)
    }

    // MARK: - Delta Time Independence

    func testDeltaTimeDoesNotAffectInput() {
        let entity = world.createEntity()
        world.addComponent(component: InputComponent(), to: entity)

        // Different delta times should not affect the input values
        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 0)))
        system.update(deltaTime: 0.001, world: world)
        var input = world.getComponent(type: InputComponent.self, for: entity)
        let input1 = input!.moveDirection

        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 0)))
        system.update(deltaTime: 1.0, world: world)
        input = world.getComponent(type: InputComponent.self, for: entity)
        let input2 = input!.moveDirection

        XCTAssertEqual(input1, input2)
    }
}
