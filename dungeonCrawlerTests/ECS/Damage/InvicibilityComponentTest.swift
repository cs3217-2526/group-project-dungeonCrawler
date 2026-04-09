//
//  InvicibilityComponentTest.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 30/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler
 
final class InvincibilityComponentTests: XCTestCase {
    
    var world: World!
    var entity1: Entity!
    var invincibility1: InvincibilityComponent!
    var invincibility2: InvincibilityComponent!
    var zeroComponent: InvincibilityComponent!

    override func setUp() {
        super.setUp()
        world = World()
        entity1 = world.createEntity()
        invincibility1 = InvincibilityComponent()                 // Default 0.5s
        invincibility2 = InvincibilityComponent(remainingTime: 1.0)
        zeroComponent = InvincibilityComponent(remainingTime: 0)
    }

    override func tearDown() {
        world = nil
        entity1 = nil
        invincibility1 = nil
        invincibility2 = nil
        zeroComponent = nil
        super.tearDown()
    }
    
    // MARK: - Initialisation
    
    func testDefaultRemainingTime() {
        XCTAssertEqual(invincibility1.remainingTime, 0.5, accuracy: 0.001)
    }
    
    func testCustomRemainingTime() {
        XCTAssertEqual(invincibility2.remainingTime, 1.0, accuracy: 0.001)
    }
    
    func testZeroRemainingTime() {
        XCTAssertEqual(zeroComponent.remainingTime, 0, accuracy: 0.001)
    }
    
    // MARK: - Mutation
    
    func testRemainingTimeCanBeDecremented() {
        invincibility1.remainingTime -= 0.1
        XCTAssertEqual(invincibility1.remainingTime, 0.4, accuracy: 0.001)
    }
    
    // MARK: - World integration
    
    func testComponentCanBeAddedToEntity() {
        world.addComponent(component: invincibility1, to: entity1)
        XCTAssertNotNil(world.getComponent(type: InvincibilityComponent.self, for: entity1))
    }
    
    func testComponentCanBeRemovedFromEntity() {
        world.addComponent(component: invincibility1, to: entity1)
        XCTAssertNotNil(world.getComponent(type: InvincibilityComponent.self, for: entity1))
        
        world.removeComponent(type: InvincibilityComponent.self, from: entity1)
        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity1))
    }
}
