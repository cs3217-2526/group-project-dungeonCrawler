//
//  PlayerDeathEventTest.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 30/3/26.
//


import Foundation
import XCTest
@testable import dungeonCrawler

final class PlayerDeathEventTests: XCTestCase {

    var event: PlayerDeathEvent!

    override func setUp() {
        super.setUp()
        event = PlayerDeathEvent()
    }

    override func tearDown() {
        event = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func testDefaultPlayerDiedIsFalse() {
        XCTAssertFalse(event.playerDied)
    }

    // MARK: - Record

    func testRecordSetsPlayerDiedTrue() {
        event.record()
        XCTAssertTrue(event.playerDied)
    }

    func testRecordIsIdempotent() {
        event.record()
        event.record()
        XCTAssertTrue(event.playerDied)
    }

    // MARK: - Reset

    func testResetClearsPlayerDied() {
        event.record()
        event.reset()
        XCTAssertFalse(event.playerDied)
    }

    func testResetOnFreshEventDoesNotCrash() {
        event.reset()
        XCTAssertFalse(event.playerDied)
    }

    func testCanRecordAgainAfterReset() {
        event.record()
        event.reset()
        event.record()
        XCTAssertTrue(event.playerDied)
    }
}
