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

    override func setUp() {
        super.setUp()
        world = World()
    }

    override func tearDown() {
        world = nil
        super.tearDown()
    }

    func testMoveSpeedCurrentEqualsBase() {
        let speed = MoveSpeedComponent(base: 90)
        XCTAssertEqual(speed.value.current, 90, accuracy: Float(0.001))
    }

    func testMoveSpeedIsComponent() {
        let entity = world.createEntity()
        world.addComponent(component: MoveSpeedComponent(base: 90), to: entity)
        let retrieved = world.getComponent(type: MoveSpeedComponent.self, for: entity)
        XCTAssertNotNil(retrieved)
    }

    func testMoveSpeedCanBeModified() {
        let entity = world.createEntity()
        world.addComponent(component: MoveSpeedComponent(base: 90), to: entity)
        world.modifyComponent(type: MoveSpeedComponent.self, for: entity) { speed in
            speed.value.current = 150
        }
        let retrieved = world.getComponent(type: MoveSpeedComponent.self, for: entity)
        XCTAssertEqual(retrieved!.value.current, 150, accuracy: Float(0.001))
    }
}
