//
//  StatValueTests.swift
//  dungeonCrawlerTests
//
//  Created by Ger Teck on 17/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class StatValueTests: XCTestCase {

    var stat1: StatValue!
    var stat2: StatValue!

    override func setUp() {
        super.setUp()
        // Initialize standard test instances
        stat1 = StatValue(base: 50)
        stat2 = StatValue(base: 50, max: 100)
    }

    override func tearDown() {
        stat1 = nil
        stat2 = nil
        super.tearDown()
    }

    // MARK: - Initialisation

    func testInitSetsCurrentToBase() {
        XCTAssertEqual(stat1.current, 50, accuracy: 0.001)
    }

    func testInitDefaultMaxIsNil() {
        XCTAssertNil(stat1.max)
    }

    func testInitCustomMax() {
        XCTAssertEqual(stat2.max, 100.0)
    }

    // MARK: - Clamping

    func testClampAboveMax() {
        stat2.current = 150
        stat2.clampToMax()
        XCTAssertEqual(stat2.current, 100, accuracy: 0.001)
    }

    func testClampWithinBoundsUnchanged() {
        stat2.current = 75
        stat2.clampToMax()
        XCTAssertEqual(stat2.current, 75, accuracy: 0.001)
    }

    func testClampNilMaxAllowsAnyValue() {
        stat1.current = 999_999
        stat1.clampToMax()
        XCTAssertEqual(stat1.current, 999_999, accuracy: 0.001)
    }

    func testClampExactMaxBoundaryUnchanged() {
        stat2.current = 100
        stat2.clampToMax()
        XCTAssertEqual(stat2.current, 100, accuracy: 0.001)
    }

    func testCurrentCanGoBelowZero() {
        stat2.current = -25
        stat2.clampToMax()
        XCTAssertEqual(stat2.current, -25, accuracy: 0.001)
    }

    // MARK: - Semantics

    func testValueSemantics() {
        var copy = stat1
        copy!.current = 999
        XCTAssertEqual(stat1.current, 50, accuracy: 0.001)
    }
}
