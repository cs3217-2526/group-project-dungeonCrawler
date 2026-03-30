//
//  SystemManagerTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

// MARK: - Mock Systems for Testing

final class MockSystemA: System {
    var updateCallCount = 0
    var lastDeltaTime: Double = 0

    func update(deltaTime: Double, world: World) {
        updateCallCount += 1
        lastDeltaTime = deltaTime
    }
}

final class MockSystemB: System {
    var updateCallCount = 0
    var dependencies: [System.Type] { [MockSystemA.self] }

    func update(deltaTime: Double, world: World) {
        updateCallCount += 1
    }
}

final class MockSystemC: System {
    var updateCallCount = 0
    var dependencies: [System.Type] { [MockSystemB.self] }

    func update(deltaTime: Double, world: World) {
        updateCallCount += 1
    }
}

// Tracks global execution order across systems
final class OrderTrackingSystem: System {
    var executionOrder: [Int] = []
    static var globalExecutionCounter = 0

    func update(deltaTime: Double, world: World) {
        OrderTrackingSystem.globalExecutionCounter += 1
        executionOrder.append(OrderTrackingSystem.globalExecutionCounter)
    }

    static func reset() {
        globalExecutionCounter = 0
    }
}

// OrderTrackingSystem subclasses for distinct type identities
final class TrackingSystemFirst: System {
    var executionOrder: [Int] = []
    func update(deltaTime: Double, world: World) {
        OrderTrackingSystem.globalExecutionCounter += 1
        executionOrder.append(OrderTrackingSystem.globalExecutionCounter)
    }
}

final class TrackingSystemSecond: System {
    var executionOrder: [Int] = []
    var dependencies: [System.Type] { [TrackingSystemFirst.self] }
    func update(deltaTime: Double, world: World) {
        OrderTrackingSystem.globalExecutionCounter += 1
        executionOrder.append(OrderTrackingSystem.globalExecutionCounter)
    }
}

final class TrackingSystemThird: System {
    var executionOrder: [Int] = []
    var dependencies: [System.Type] { [TrackingSystemSecond.self] }
    func update(deltaTime: Double, world: World) {
        OrderTrackingSystem.globalExecutionCounter += 1
        executionOrder.append(OrderTrackingSystem.globalExecutionCounter)
    }
}

// MARK: - SystemManager Tests

@MainActor
final class SystemManagerTests: XCTestCase {

    var systemManager: SystemManager!
    var world: World!
    var world1: World!
    var world2: World!

    override func setUp() {
        super.setUp()
        systemManager = SystemManager()
        world = World()
        world1 = World()
        world2 = World()
        OrderTrackingSystem.reset()
    }

    override func tearDown() {
        systemManager = nil
        world = nil
        world1 = nil
        world2 = nil
        super.tearDown()
    }

    // MARK: - Registration

    func testRegisterSingleSystem() {
        let system = MockSystemA()
        systemManager.register(system)

        systemManager.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(system.updateCallCount, 1)
    }

    func testRegisterMultipleSystems() {
        let systemA = MockSystemA()
        let systemB = MockSystemB()
        let systemC = MockSystemC()

        systemManager.register(systemA)
        systemManager.register(systemB)
        systemManager.register(systemC)

        systemManager.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(systemA.updateCallCount, 1)
        XCTAssertEqual(systemB.updateCallCount, 1)
        XCTAssertEqual(systemC.updateCallCount, 1)
    }

    func testUnregisterSystem() {
        let systemA = MockSystemA()
        let systemB = MockSystemB()

        systemManager.register(systemA)
        systemManager.register(systemB)

        systemManager.update(deltaTime: 0.016, world: world)
        XCTAssertEqual(systemA.updateCallCount, 1)
        XCTAssertEqual(systemB.updateCallCount, 1)

        systemManager.unregister(MockSystemA.self)

        systemManager.update(deltaTime: 0.016, world: world)
        XCTAssertEqual(systemA.updateCallCount, 1) // Should not increase
        XCTAssertEqual(systemB.updateCallCount, 2) // Should increase
    }

    func testUnregisterNonexistentSystem() {
        let systemA = MockSystemA()
        systemManager.register(systemA)

        // Should not crash
        systemManager.unregister(MockSystemB.self)

        systemManager.update(deltaTime: 0.016, world: world)
        XCTAssertEqual(systemA.updateCallCount, 1)
    }

    // MARK: - Dependency Ordering

    func testSystemExecutionOrder() {
        let first  = TrackingSystemFirst()
        let second = TrackingSystemSecond()
        let third  = TrackingSystemThird()

        // Register in reverse dependency order to confirm sort works
        systemManager.register(third)
        systemManager.register(second)
        systemManager.register(first)

        systemManager.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(first.executionOrder.first,  1, "First (no deps) should run first")
        XCTAssertEqual(second.executionOrder.first, 2, "Second (depends on First) should run second")
        XCTAssertEqual(third.executionOrder.first,  3, "Third (depends on Second) should run third")
    }

    func testSystemsWithNoDependenciesAllRun() {
        let systemA = MockSystemA()
        let systemB = MockSystemA() // Same type — second registration overwrites first
        systemManager.register(systemA)
        _ = systemB // intentionally unused; same type as A so only one runs

        systemManager.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(systemA.updateCallCount, 1)
    }

    func testDependencyOrderMaintainedAfterLateRegistration() {
        let first  = TrackingSystemFirst()
        let third  = TrackingSystemThird()

        systemManager.register(first)
        systemManager.register(third)
        systemManager.update(deltaTime: 0.016, world: world)

        // Register the missing middle dependency
        let second = TrackingSystemSecond()
        systemManager.register(second)

        OrderTrackingSystem.reset()
        systemManager.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(first.executionOrder.last,  1, "First should still run first after late registration")
        XCTAssertEqual(second.executionOrder.last, 2, "Newly registered Second should slot in the middle")
        XCTAssertEqual(third.executionOrder.last,  3, "Third should still run last")
    }

    // MARK: - Update Behavior

    func testUpdatePassesDeltaTime() {
        let system = MockSystemA()
        systemManager.register(system)

        let deltaTime = 0.123
        systemManager.update(deltaTime: deltaTime, world: world)

        XCTAssertEqual(system.lastDeltaTime, deltaTime, accuracy: 0.0001)
    }

    func testMultipleUpdateCalls() {
        let system = MockSystemA()
        systemManager.register(system)

        systemManager.update(deltaTime: 0.016, world: world)
        systemManager.update(deltaTime: 0.016, world: world)
        systemManager.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(system.updateCallCount, 3)
    }

    func testUpdateWithNoSystems() {
        // Should not crash
        systemManager.update(deltaTime: 0.016, world: world)
    }

    func testUpdateWithDifferentWorlds() {
        let system = MockSystemA()
        systemManager.register(system)

        systemManager.update(deltaTime: 0.016, world: world1)
        systemManager.update(deltaTime: 0.016, world: world2)

        XCTAssertEqual(system.updateCallCount, 2)
    }

    // MARK: - Integration with Real Systems

    func testIntegrationWithMovementSystem() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(linear: SIMD2<Float>(10, 0)), to: entity)
        world.addComponent(component: InputComponent(moveDirection: SIMD2<Float>(1, 0)), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        let movementSystem = MovementSystem()
        systemManager.register(movementSystem)

        systemManager.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
        XCTAssertGreaterThan(transform!.position.x, 0)
    }

    func testMultipleSystemsWorkingTogether() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: SIMD2<Float>(0, 0)), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 100), to: entity)

        let commandQueues = CommandQueues()
        commandQueues.register(MoveCommand.self)
        commandQueues.push(MoveCommand(id: UUID(), rawMoveVector: SIMD2<Float>(1, 0)))

        let inputSystem = InputSystem(commandQueues: commandQueues)
        let movementSystem = MovementSystem()

        systemManager.register(inputSystem)
        systemManager.register(movementSystem)

        systemManager.update(deltaTime: 0.1, world: world)

        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input?.moveDirection.x, 1)

        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
    }
}
