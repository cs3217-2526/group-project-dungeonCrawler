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
    
    var enemyState: EnemyStateComponent!
    var enemyStateCustom: EnemyStateComponent!
    var straightLineStrategy: StraightLineChaseStrategy!
    var wanderStrategy: WanderStrategy!
    var wanderEnemy: EnemyStateComponent!
    var straightEnemy: EnemyStateComponent!
    
    override func setUp() {
        super.setUp()
        enemyState = EnemyStateComponent()
        enemyStateCustom = EnemyStateComponent(detectionRadius: 200)
        straightLineStrategy = StraightLineChaseStrategy(chaseSpeed: 120)
        wanderStrategy = WanderStrategy(wanderRadius: 50, wanderSpeed: 25)
        wanderEnemy = EnemyStateComponent(chaseStrategy: wanderStrategy)
        straightEnemy = EnemyStateComponent(chaseStrategy: straightLineStrategy)
    }
    
    override func tearDown() {
        enemyState = nil
        enemyStateCustom = nil
        straightLineStrategy = nil
        wanderStrategy = nil
        super.tearDown()
    }

    // MARK: - Default initialisation

    func testDefaultModeIsWander() {
        XCTAssertTrue(enemyState.mode == .wander)
    }

    func testDefaultDetectionRadius() {
        XCTAssertEqual(enemyState.detectionRadius, 150, accuracy: 0.001)
    }

    func testDefaultLoseRadius() {
        XCTAssertEqual(enemyState.loseRadius, 225, accuracy: 0.001)
    }

    // MARK: - Default strategies

    func testDefaultWanderStrategyIsWanderStrategy() {
        XCTAssertTrue(enemyState.wanderStrategy is WanderStrategy)
    }

    func testDefaultChaseStrategyIsStraightLineChaseStrategy() {
        XCTAssertTrue(enemyState.chaseStrategy is StraightLineChaseStrategy)
    }

    // MARK: - Logical invariants

    func testLoseRadiusIsGreaterThanDetectionRadius() {
        XCTAssertGreaterThan(enemyState.loseRadius, enemyState.detectionRadius)
    }

    // MARK: - Custom initialisation

    func testCustomDetectionRadius() {
        XCTAssertEqual(enemyStateCustom.detectionRadius, 200, accuracy: 0.001)
    }

    func testCustomWanderStrategy() {
        let wander = wanderEnemy.chaseStrategy as? WanderStrategy
        XCTAssertNotNil(wander)
        XCTAssertEqual(wander!.wanderRadius, 50, accuracy: 0.001)
        XCTAssertEqual(wander!.wanderSpeed, 25, accuracy: 0.001)
    }

    func testCustomChaseStrategy() {
        let chase = straightEnemy.chaseStrategy as? StraightLineChaseStrategy
        XCTAssertNotNil(chase)
        XCTAssertEqual(chase!.chaseSpeed, 120, accuracy: 0.001)
    }

    // MARK: - Mutation

    func testModeCanBeChangedToChase() {
        enemyState.mode = .chase
        XCTAssertTrue(enemyState.mode == .chase)
    }

    func testModeCanRevertToWander() {
        enemyState.mode = .chase
        enemyState.mode = .wander
        XCTAssertTrue(enemyState.mode == .wander)
    }

    func testWanderStrategyCanBeSwapped() {
        enemyState.wanderStrategy = straightLineStrategy
        XCTAssertTrue(enemyState.wanderStrategy is StraightLineChaseStrategy)
    }

    func testChaseStrategyCanBeSwapped() {
        enemyState.chaseStrategy = wanderStrategy
        XCTAssertTrue(enemyState.chaseStrategy is WanderStrategy)
    }
}
