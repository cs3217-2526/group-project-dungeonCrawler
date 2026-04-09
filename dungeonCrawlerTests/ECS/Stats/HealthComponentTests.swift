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
    var entity1: Entity!
    var entity2: Entity!
    var health1: HealthComponent!
    var health2: HealthComponent!
    var health3: HealthComponent!

    override func setUp() {
        super.setUp()
        world   = World()
        entity1 = world.createEntity()
        entity2 = world.createEntity()
        
        // Initializing common component configurations for testing
        health1 = HealthComponent(base: 100)
        health2 = HealthComponent(base: 50, max: 200)
        health3 = HealthComponent(base: 80)
    }

    override func tearDown() {
        world   = nil
        entity1 = nil
        entity2 = nil
        health1 = nil
        health2 = nil
        health3 = nil
        super.tearDown()
    }

    // MARK: - Health Property Tests

    func testHealthDefaultMaxEqualsBase() {
        XCTAssertEqual(health1.value.max, 100.0)
    }

    func testHealthCurrentEqualsBase() {
        XCTAssertEqual(health3.value.current, 80, accuracy: 0.001)
    }

    func testHealthCustomMax() {
        XCTAssertEqual(health2.value.max, 200.0)
    }

    func testHealthReduceCurrent() {
        health1.value.current = 40
        XCTAssertEqual(health1.value.current, 40, accuracy: 0.001)
    }

    // MARK: - World Integration Tests

    func testHealthIsComponent() {
        world.addComponent(component: health1, to: entity1)
        
        let retrieved = world.getComponent(type: HealthComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.value.current, 100, accuracy: Float(0.001))
    }
}
