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
    
    // Tracked Entities
    var enemyEntity: Entity!
    var playerEntity: Entity!
    var secondEnemyEntity: Entity!
    var miscEntity: Entity!
    
    // Tracked Components
    var enemyHealth: HealthComponent!
    var playerHealth: HealthComponent!
    var secondEnemyHealth: HealthComponent!
    var playerTag: PlayerTagComponent!
    var miscTransform: TransformComponent!

    override func setUp() {
        super.setUp()
        world = World()
        destructionQueue = DestructionQueue()
        playerDeathEvent = PlayerDeathEvent()
        system = HealthSystem(destructionQueue: destructionQueue, playerDeathEvent: playerDeathEvent)
        
        // Initialize Primary Enemy
        enemyEntity = world.createEntity()
        enemyHealth = HealthComponent(base: 100)
        world.addComponent(component: enemyHealth, to: enemyEntity)
        
        // Initialize Second Enemy (for multi-entity tests)
        secondEnemyEntity = world.createEntity()
        secondEnemyHealth = HealthComponent(base: 100)
        world.addComponent(component: secondEnemyHealth, to: secondEnemyEntity)
        
        // Initialize Player
        playerEntity = world.createEntity()
        playerHealth = HealthComponent(base: 100)
        playerTag = PlayerTagComponent()
        world.addComponent(component: playerHealth, to: playerEntity)
        world.addComponent(component: playerTag, to: playerEntity)
        
        // Initialize Misc Entity (for edge case tests)
        miscEntity = world.createEntity()
        miscTransform = TransformComponent()
        world.addComponent(component: miscTransform, to: miscEntity)
    }

    override func tearDown() {
        system = nil
        destructionQueue = nil
        playerDeathEvent = nil
        world = nil
        
        enemyEntity = nil
        playerEntity = nil
        secondEnemyEntity = nil
        miscEntity = nil
        
        enemyHealth = nil
        playerHealth = nil
        secondEnemyHealth = nil
        playerTag = nil
        miscTransform = nil
        
        super.tearDown()
    }

    // MARK: - Enemy destruction (non-player entities)
     
    func testEnemyQueuedForDestructionAtZeroHealth() {
        enemyHealth.value.current = 0
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: enemyEntity))
    }
 
    func testOnlyZeroHPEnemiesDestroyed() {
        enemyHealth.value.current = 0
        secondEnemyHealth.value.current = 50
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertNil(world.getComponent(type: HealthComponent.self, for: enemyEntity))
        XCTAssertNotNil(world.getComponent(type: HealthComponent.self, for: secondEnemyEntity))
    }
 
    // MARK: - Player death
 
    func testPlayerEntityNotDestroyedWhenHPIsZero() {
        playerHealth.value.current = 0
 
        system.update(deltaTime: 0.016, world: world)
        destructionQueue.flush(world: world)
 
        XCTAssertTrue(world.isAlive(entity: playerEntity))
    }
 
    // MARK: - Edge cases
 
    func testEntityWithoutHealthComponentUnaffected() {
        system.update(deltaTime: 0.016, world: world)
 
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: miscEntity))
    }
}
