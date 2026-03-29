//
//  HealthSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Ger Teck on 17/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class HealthSystemTests: XCTestCase {

    var world: World!
    var destructionQueue: DestructionQueue!
    var playerDeathEvent: PlayerDeathEvent!
    var system: HealthSystem!

    override func setUp() {
        super.setUp()
        world = World()
        destructionQueue = DestructionQueue()
        playerDeathEvent = PlayerDeathEvent()
        system = HealthSystem(destructionQueue: destructionQueue, playerDeathEvent: playerDeathEvent)
    }

    override func tearDown() {
        system = nil
        destructionQueue = nil
        playerDeathEvent = nil
        world = nil
        
        super.tearDown()
    }

    // MARK: - Enemy destruction (non-player entities)
     
    func testEnemyQueuedForDestructionAtZeroHealth() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: entity)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: entity))
    }
 
    func testEnemyQueuedForDestructionAtNegativeHealth() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = -1
        world.addComponent(component: health, to: entity)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: entity))
    }
 
    func testEnemySurvivesPositiveHealth() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 50
        world.addComponent(component: health, to: entity)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: entity))
    }
 
    func testEnemySurvivesAtOneHP() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 1
        world.addComponent(component: health, to: entity)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: entity))
    }
 
    func testOnlyZeroHPEnemiesDestroyed() {
        let dead = world.createEntity()
        var deadHealth = HealthComponent(base: 100)
        deadHealth.value.current = 0
        world.addComponent(component: deadHealth, to: dead)
 
        let alive = world.createEntity()
        var aliveHealth = HealthComponent(base: 100)
        aliveHealth.value.current = 50
        world.addComponent(component: aliveHealth, to: alive)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: dead))
        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: alive))
    }
 
    func testDestroyedEnemyLosesAllComponents() {
        let entity = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: entity)
        world.addComponent(component: TransformComponent(), to: entity)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: entity))
        XCTAssertNil(world.getComponent(type: TransformComponent.self, for: entity))
    }
 
    // MARK: - Player death (player entity with PlayerTagComponent)
 
    func testPlayerDeathEventFiredWhenPlayerHPIsZero() {
        let player = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: player)
        world.addComponent(component: PlayerTagComponent(), to: player)
 
        system.update(deltaTime: 0.016, world: world)
 
        XCTAssertTrue(playerDeathEvent.playerDied)
    }
 
    func testPlayerEntityNotDestroyedWhenHPIsZero() {
        // Player must stay alive so camera / HUD systems don't break mid-frame
        let player = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: player)
        world.addComponent(component: PlayerTagComponent(), to: player)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertTrue(world.isAlive(entity: player))
    }
 
    func testPlayerDeathEventNotFiredWhenPlayerHPIsPositive() {
        let player = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 30
        world.addComponent(component: health, to: player)
        world.addComponent(component: PlayerTagComponent(), to: player)
 
        system.update(deltaTime: 0.016, world: world)
 
        XCTAssertFalse(playerDeathEvent.playerDied)
    }
 
    func testPlayerDeathDoesNotEnqueueDestructionForPlayer() {
        let player = world.createEntity()
        var health = HealthComponent(base: 100)
        health.value.current = 0
        world.addComponent(component: health, to: player)
        world.addComponent(component: PlayerTagComponent(), to: player)
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        // Player is still alive — destruction queue must NOT have touched it
        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: player))
    }
 
    // MARK: - Edge cases
 
    func testEntityWithoutHealthComponentUnaffected() {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(), to: entity)
 
        system.update(deltaTime: 0.016, world: world)
 
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
    }
 
    func testEmptyWorldDoesNotCrash() {
        system.update(deltaTime: 0.016, world: world)
    }
}
