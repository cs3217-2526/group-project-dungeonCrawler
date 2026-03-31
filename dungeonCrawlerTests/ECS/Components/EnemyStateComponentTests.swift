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

    func testDefaultModeIsWander() {
        let state = EnemyStateComponent()
        XCTAssertTrue(state.mode == .wander)
    }

    func testDefaultDetectionRadius() {
        let state = EnemyStateComponent()
        XCTAssertEqual(state.detectionRadius, 150, accuracy: 0.001)
    }

    func testDefaultLoseRadius() {
        let state = EnemyStateComponent()
        XCTAssertEqual(state.loseRadius, 225, accuracy: 0.001)
    }

    // MARK: - Default strategies

    func testDefaultWanderStrategyIsWanderStrategy() {
        let state = EnemyStateComponent()
        XCTAssertTrue(state.wanderStrategy is WanderStrategy)
    }

    func testDefaultChaseStrategyIsStraightLineChaseStrategy() {
        let state = EnemyStateComponent()
        XCTAssertTrue(state.chaseStrategy is StraightLineChaseStrategy)
    }

    // MARK: - Logical invariants

    func testLoseRadiusIsGreaterThanDetectionRadius() {
        let state = EnemyStateComponent()
        XCTAssertGreaterThan(state.loseRadius, state.detectionRadius)
    }

    // MARK: - Custom initialisation

    func testCustomDetectionRadius() {
        let state = EnemyStateComponent(detectionRadius: 200)
        XCTAssertEqual(state.detectionRadius, 200, accuracy: 0.001)
    }

    func testCustomLoseRadius() {
        let state = EnemyStateComponent(loseRadius: 300)
        XCTAssertEqual(state.loseRadius, 300, accuracy: 0.001)
    }

    func testCustomWanderStrategy() {
        let customWander = WanderStrategy(wanderRadius: 50, wanderSpeed: 25)
        let state = EnemyStateComponent(wanderStrategy: customWander)
        let wander = state.wanderStrategy as? WanderStrategy
        XCTAssertNotNil(wander)
        XCTAssertEqual(wander!.wanderRadius, 50, accuracy: 0.001)
        XCTAssertEqual(wander!.wanderSpeed, 25, accuracy: 0.001)
    }

    func testCustomChaseStrategy() {
        let customChase = StraightLineChaseStrategy(chaseSpeed: 120)
        let state = EnemyStateComponent(chaseStrategy: customChase)
        let chase = state.chaseStrategy as? StraightLineChaseStrategy
        XCTAssertNotNil(chase)
        XCTAssertEqual(chase!.chaseSpeed, 120, accuracy: 0.001)
    }

    // MARK: - Mutation

    func testModeCanBeChangedToChase() {
        var state = EnemyStateComponent()
        state.mode = .chase
        XCTAssertTrue(state.mode == .chase)
    }

    func testModeCanRevertToWander() {
        var state = EnemyStateComponent()
        state.mode = .chase
        state.mode = .wander
        XCTAssertTrue(state.mode == .wander)
    }

    func testWanderStrategyCanBeSwapped() {
        var state = EnemyStateComponent()
        state.wanderStrategy = StraightLineChaseStrategy()
        XCTAssertTrue(state.wanderStrategy is StraightLineChaseStrategy)
    }

    func testChaseStrategyCanBeSwapped() {
        var state = EnemyStateComponent()
        state.chaseStrategy = WanderStrategy()
        XCTAssertTrue(state.chaseStrategy is WanderStrategy)
    }
}
