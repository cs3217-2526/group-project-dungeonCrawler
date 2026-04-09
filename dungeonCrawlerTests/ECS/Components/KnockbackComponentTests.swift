//
//  KnockbackComponentTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 19/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

final class KnockbackComponentTests: XCTestCase {

    var world: World!
    var entity1: Entity!
    var knockback1: KnockbackComponent!
    var knockback2: KnockbackComponent!
    var knockback3: KnockbackComponent!

    override func setUp() {
        super.setUp()
        world      = World()
        entity1    = world.createEntity()
        
        // Initializing common component configurations for testing
        knockback1 = KnockbackComponent(velocity: .zero) // Default 0.2s
        knockback2 = KnockbackComponent(velocity: SIMD2<Float>(100, -50), remainingTime: 0.5)
        knockback3 = KnockbackComponent(velocity: SIMD2(200, 300), remainingTime: 0.3)
    }

    override func tearDown() {
        world      = nil
        entity1    = nil
        knockback1 = nil
        knockback2 = nil
        knockback3 = nil
        super.tearDown()
    }

    // MARK: - Default initialisation

    func testDefaultRemainingTime() {
        XCTAssertEqual(knockback1.remainingTime, 0.2, accuracy: 0.001)
    }

    func testVelocityStoredCorrectly() {
        XCTAssertEqual(knockback2.velocity.x, 100, accuracy: 0.001)
        XCTAssertEqual(knockback2.velocity.y, -50, accuracy: 0.001)
    }

    // MARK: - Custom initialisation

    func testCustomRemainingTime() {
        XCTAssertEqual(knockback2.remainingTime, 0.5, accuracy: 0.001)
    }

    func testCustomVelocityAndDuration() {
        XCTAssertEqual(knockback3.velocity.x, 200, accuracy: 0.001)
        XCTAssertEqual(knockback3.velocity.y, 300, accuracy: 0.001)
        XCTAssertEqual(knockback3.remainingTime, 0.3, accuracy: 0.001)
    }

    // MARK: - Mutation

    func testRemainingTimeCanBeDecremented() {
        knockback1.remainingTime = 0.3
        knockback1.remainingTime -= 0.1
        XCTAssertEqual(knockback1.remainingTime, 0.2, accuracy: 0.001)
    }

    func testVelocityCanBeChanged() {
        knockback1.velocity = SIMD2(0, 200)
        XCTAssertEqual(knockback1.velocity.x, 0, accuracy: 0.001)
        XCTAssertEqual(knockback1.velocity.y, 200, accuracy: 0.001)
    }

    func testRemainingTimeCanGoBelowZero() {
        knockback1.remainingTime = 0.1
        knockback1.remainingTime -= 0.2
        XCTAssertLessThan(knockback1.remainingTime, 0)
    }
    
    // MARK: - World Integration
    
    func testKnockbackAsComponent() {
        world.addComponent(component: knockback1, to: entity1)
        let retrieved = world.getComponent(type: KnockbackComponent.self, for: entity1)
        XCTAssertNotNil(retrieved)
    }
}
