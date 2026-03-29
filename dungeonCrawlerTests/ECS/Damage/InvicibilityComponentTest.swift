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
    
    override func setUp() {
        super.setUp()
        world  = World()
    }

    override func tearDown() {
        world  = nil
        super.tearDown()
    }
 
    // MARK: - Initialisation
 
    func testDefaultRemainingTime() {
        let component = InvincibilityComponent()
        XCTAssertEqual(component.remainingTime, 0.5, accuracy: 0.001)
    }
 
    func testCustomRemainingTime() {
        let component = InvincibilityComponent(remainingTime: 1.0)
        XCTAssertEqual(component.remainingTime, 1.0, accuracy: 0.001)
    }
 
    func testZeroRemainingTime() {
        let component = InvincibilityComponent(remainingTime: 0)
        XCTAssertEqual(component.remainingTime, 0, accuracy: 0.001)
    }
 
    // MARK: - Mutation
 
    func testRemainingTimeCanBeDecremented() {
        var component = InvincibilityComponent(remainingTime: 0.5)
        component.remainingTime -= 0.1
        XCTAssertEqual(component.remainingTime, 0.4, accuracy: 0.001)
    }
 
    // MARK: - World integration
 
    func testComponentCanBeAddedToEntity() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.5), to: entity)
        XCTAssertNotNil(world.getComponent(type: InvincibilityComponent.self, for: entity))
    }
 
    func testComponentCanBeRemovedFromEntity() {
        let entity = world.createEntity()
        world.addComponent(component: InvincibilityComponent(), to: entity)
        world.removeComponent(type: InvincibilityComponent.self, from: entity)
        XCTAssertNil(world.getComponent(type: InvincibilityComponent.self, for: entity))
    }
}
