//
//  HealthComponentTests.swift
//  dungeonCrawlerTests
//
//  Created by Ger Teck on 17/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class HealthComponentTests: XCTestCase {

    var world: World!

    override func setUp() {
        super.setUp()
        world = World()
    }

    override func tearDown() {
        world = nil
        super.tearDown()
    }

    func testHealthDefaultMaxEqualsBase() {
        let health = HealthComponent(base: 100)
        XCTAssertEqual(health.value.max, Float(100))
    }

    func testHealthCurrentEqualsBase() {
        let health = HealthComponent(base: 80)
        XCTAssertEqual(health.value.current, 80, accuracy: Float(0.001))
    }

    func testHealthCustomMax() {
        let health = HealthComponent(base: 50, max: 200)
        XCTAssertEqual(health.value.max, Float(200))
    }

    func testHealthReduceCurrent() {
        var health = HealthComponent(base: 100)
        health.value.current = 40
        XCTAssertEqual(health.value.current, 40, accuracy: Float(0.001))
    }

    func testHealthIsComponent() {
        let entity = world.createEntity()
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        let retrieved = world.getComponent(type: HealthComponent.self, for: entity)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.value.current, 100, accuracy: Float(0.001))
    }
}
