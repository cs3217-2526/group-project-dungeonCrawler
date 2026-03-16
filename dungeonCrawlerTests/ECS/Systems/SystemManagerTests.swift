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
    var priority: Int
    var updateCallCount = 0
    var lastDeltaTime: Double = 0
    
    init(priority: Int = 10) {
        self.priority = priority
    }
    
    func update(deltaTime: Double, world: World) {
        updateCallCount += 1
        lastDeltaTime = deltaTime
    }
}
 
final class MockSystemB: System {
    var priority: Int
    var updateCallCount = 0
    
    init(priority: Int = 20) {
        self.priority = priority
    }
    
    func update(deltaTime: Double, world: World) {
        updateCallCount += 1
    }
}
 
final class MockSystemC: System {
    var priority: Int
    var updateCallCount = 0
    
    init(priority: Int = 30) {
        self.priority = priority
    }
    
    func update(deltaTime: Double, world: World) {
        updateCallCount += 1
    }
}
 
// System that tracks execution order
final class OrderTrackingSystem: System {
    var priority: Int
    var executionOrder: [Int] = []
    static var globalExecutionCounter = 0
    
    init(priority: Int) {
        self.priority = priority
    }
    
    func update(deltaTime: Double, world: World) {
        OrderTrackingSystem.globalExecutionCounter += 1
        executionOrder.append(OrderTrackingSystem.globalExecutionCounter)
    }
    
    static func reset() {
        globalExecutionCounter = 0
    }
}
 
// MARK: - SystemManager Tests
 
final class SystemManagerTests: XCTestCase {
    
    var systemManager: SystemManager!
    var world: World!
    var world1: World!
    var world2: World!
    var mockInput: MockInputProvider!
    
    override func setUp() {
        super.setUp()
        systemManager = SystemManager()
        world = World()
        world1 = World()
        world2 = World()
        mockInput = MockInputProvider()
        OrderTrackingSystem.reset()
    }
    
    override func tearDown() {
        systemManager = nil
        world = nil
        world1 = nil
        world2 = nil
        mockInput = nil
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
    
    // MARK: - Priority Ordering
    
    func testSystemExecutionOrder() {
        let system1 = OrderTrackingSystem(priority: 30)
        let system2 = OrderTrackingSystem(priority: 10)
        let system3 = OrderTrackingSystem(priority: 20)
        
        // Register in random order
        systemManager.register(system1)
        systemManager.register(system2)
        systemManager.register(system3)
        
        systemManager.update(deltaTime: 0.016, world: world)
        
        // Verify execution order: 10, 20, 30
        XCTAssertEqual(system2.executionOrder.first, 1) // priority 10 runs first
        XCTAssertEqual(system3.executionOrder.first, 2) // priority 20 runs second
        XCTAssertEqual(system1.executionOrder.first, 3) // priority 30 runs third
    }
    
    func testSystemsWithSamePriority() {
        let systemA = MockSystemA(priority: 10)
        let systemB = MockSystemB(priority: 10)
        
        systemManager.register(systemA)
        systemManager.register(systemB)
        
        systemManager.update(deltaTime: 0.016, world: world)
        
        // Both should run (order doesn't matter for same priority)
        XCTAssertEqual(systemA.updateCallCount, 1)
        XCTAssertEqual(systemB.updateCallCount, 1)
    }
    
    func testPriorityMaintainedAfterRegistration() {
        let system1 = OrderTrackingSystem(priority: 10)
        let system2 = OrderTrackingSystem(priority: 30)
        
        systemManager.register(system1)
        systemManager.register(system2)
        systemManager.update(deltaTime: 0.016, world: world)
        
        // Register new system with priority between existing systems
        let system3 = OrderTrackingSystem(priority: 20)
        systemManager.register(system3)
        
        OrderTrackingSystem.reset()
        systemManager.update(deltaTime: 0.016, world: world)
        
        // Verify order is still correct: 10, 20, 30
        XCTAssertEqual(system1.executionOrder.last, 1)
        XCTAssertEqual(system3.executionOrder.last, 2)
        XCTAssertEqual(system2.executionOrder.last, 3)
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
        
        let movementSystem = MovementSystem()
        movementSystem.defaultMoveSpeed = 100
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
        
        mockInput.rawMoveVector = SIMD2<Float>(1, 0)
        
        let movementSystem = MovementSystem()
        let inputSystem = InputSystem(inputProvider: mockInput)
        
        systemManager.register(inputSystem)
        systemManager.register(movementSystem)
        
        systemManager.update(deltaTime: 0.1, world: world)
        
        // Verify input was processed
        let input = world.getComponent(type: InputComponent.self, for: entity)
        XCTAssertEqual(input?.moveDirection.x, 1)
        
        // Verify movement occurred
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
    }
}
 
