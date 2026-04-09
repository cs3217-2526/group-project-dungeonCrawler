//
//  MoveSpeedComponentTests.swift
//  dungeonCrawlerTests
//
//  Created by Ger Teck on 17/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class MoveSpeedComponentTests: XCTestCase {

    var world: World!
    var entity1: Entity!
    var moveSpeed1: MoveSpeedComponent!

    override func setUp() {
        super.setUp()
        world      = World()
        entity1    = world.createEntity()
        moveSpeed1 = MoveSpeedComponent(base: 90)
    }

    override func tearDown() {
        world      = nil
        entity1    = nil
        moveSpeed1 = nil
        super.tearDown()
    }

    // MARK: - Properties

    func testMoveSpeedCurrentEqualsBase() {
        XCTAssertEqual(moveSpeed1.value.current, 90, accuracy: 0.001)
    }

    // MARK: - World Integration

    func testMoveSpeedIsComponent() {
        world.addComponent(component: moveSpeed1, to: entity1)
        
        let retrieved = world.getComponent(type: MoveSpeedComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
    }

    func testMoveSpeedCanBeModified() {
        world.addComponent(component: moveSpeed1, to: entity1)
        
        if let component = world.getComponent(type: MoveSpeedComponent.self, for: entity1) {
            component.value.current = 150
        }
        
        let retrieved = world.getComponent(type: MoveSpeedComponent.self, for: entity1)
        XCTAssertEqual(retrieved!.value.current, 150, accuracy: 0.001)
    }
}
