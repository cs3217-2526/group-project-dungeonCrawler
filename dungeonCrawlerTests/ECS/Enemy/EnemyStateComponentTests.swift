//
//  EnemyStateComponentTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 17/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class EnemyStateComponentTests: XCTestCase {
    
    var state: EnemyStateComponent!
    var customState: EnemyStateComponent!
    var timidStrategy1: TimidStrategy!
    var timidStrategy2: TimidStrategy!
    
    override func setUp() {
        super.setUp()
        state = EnemyStateComponent()
        timidStrategy1 = TimidStrategy()
        timidStrategy2 = TimidStrategy()
        customState = EnemyStateComponent(strategy: timidStrategy1)
    }
    
    override func tearDown() {
        timidStrategy1 = nil
        timidStrategy2 = nil
        customState = nil
        state = nil
        super.tearDown()
    }

    // MARK: - Default initialisation

    func testDefaultStrategyIsStandardStrategy() {
        XCTAssertTrue(state.strategy is StandardStrategy)
    }

    // MARK: - Custom initialisation

    func testCustomStrategyCanBePassedIn() {
        XCTAssertTrue(customState.strategy is TimidStrategy)
    }

    // MARK: - Mutation

    func testStrategyCanBeMutated() {
        state.strategy = timidStrategy2
        XCTAssertTrue(state.strategy is TimidStrategy)
    }
}
