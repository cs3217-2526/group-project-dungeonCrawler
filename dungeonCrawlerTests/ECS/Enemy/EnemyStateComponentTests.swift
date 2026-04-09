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

    // MARK: - Default initialisation

    func testDefaultStrategyIsStandardStrategy() {
        let state = EnemyStateComponent()
        XCTAssertTrue(state.strategy is StandardStrategy)
    }

    // MARK: - Custom initialisation

    func testCustomStrategyCanBePassedIn() {
        let state = EnemyStateComponent(strategy: TimidStrategy())
        XCTAssertTrue(state.strategy is TimidStrategy)
    }

    // MARK: - Mutation

    func testStrategyCanBeMutated() {
        var state = EnemyStateComponent()
        state.strategy = TimidStrategy()
        XCTAssertTrue(state.strategy is TimidStrategy)
    }
}
