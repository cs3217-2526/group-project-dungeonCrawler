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

    func testInitSetsCurrentToBase() {
        let stat = StatValue(base: 50)
        XCTAssertEqual(stat.current, 50, accuracy: 0.001)
    }

    func testInitDefaultMaxIsNil() {
        let stat = StatValue(base: 10)
        XCTAssertNil(stat.max)
    }

    func testInitCustomMax() {
        let stat = StatValue(base: 50, max: 100)
        XCTAssertEqual(stat.max, Float(100))
    }

    func testClampAboveMax() {
        var stat = StatValue(base: 50, max: 100)
        stat.current = 150
        stat.clampToMax()
        XCTAssertEqual(stat.current, 100, accuracy: 0.001)
    }

    func testClampWithinBoundsUnchanged() {
        var stat = StatValue(base: 50, max: 100)
        stat.current = 75
        stat.clampToMax()
        XCTAssertEqual(stat.current, 75, accuracy: 0.001)
    }

    func testClampNilMaxAllowsAnyValue() {
        var stat = StatValue(base: 50, max: nil)
        stat.current = 999_999
        stat.clampToMax()
        XCTAssertEqual(stat.current, 999_999, accuracy: 0.001)
    }

    func testClampExactMaxBoundaryUnchanged() {
        var stat = StatValue(base: 50, max: 100)
        stat.current = 100
        stat.clampToMax()
        XCTAssertEqual(stat.current, 100, accuracy: 0.001)
    }

    func testCurrentCanGoBelowZero() {
        var stat = StatValue(base: 50, max: 100)
        stat.current = -25
        stat.clampToMax()
        XCTAssertEqual(stat.current, -25, accuracy: 0.001)
    }

    func testValueSemantics() {
        let original = StatValue(base: 50)
        var copy = original
        copy.current = 999
        XCTAssertEqual(original.current, 50, accuracy: 0.001)
    }
}
