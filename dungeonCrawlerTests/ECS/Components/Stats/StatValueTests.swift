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

    func testInitDefaultMinIsZero() {
        let stat = StatValue(base: 10)
        XCTAssertEqual(stat.min, 0, accuracy: 0.001)
    }

    func testInitDefaultMaxIsNil() {
        let stat = StatValue(base: 10)
        XCTAssertNil(stat.max)
    }

    func testInitCustomMinAndMax() {
        let stat = StatValue(base: 50, min: 10, max: 100)
        XCTAssertEqual(stat.min, 10, accuracy: Float(0.001))
        XCTAssertEqual(stat.max, Float(100))
    }

    func testClampAboveMax() {
        var stat = StatValue(base: 50, min: 0, max: 100)
        stat.current = 150
        stat.clampToBounds()
        XCTAssertEqual(stat.current, 100, accuracy: 0.001)
    }

    func testClampBelowMin() {
        var stat = StatValue(base: 50, min: 10, max: 100)
        stat.current = 5
        stat.clampToBounds()
        XCTAssertEqual(stat.current, 10, accuracy: 0.001)
    }

    func testClampWithinBoundsUnchanged() {
        var stat = StatValue(base: 50, min: 0, max: 100)
        stat.current = 75
        stat.clampToBounds()
        XCTAssertEqual(stat.current, 75, accuracy: 0.001)
    }

    func testClampNilMaxAllowsAnyValue() {
        var stat = StatValue(base: 50, min: 0, max: nil)
        stat.current = 999_999
        stat.clampToBounds()
        XCTAssertEqual(stat.current, 999_999, accuracy: 0.001)
    }

    func testClampExactBoundaryUnchanged() {
        var statMin = StatValue(base: 50, min: 0, max: 100)
        statMin.current = 0
        statMin.clampToBounds()
        XCTAssertEqual(statMin.current, 0, accuracy: 0.001)

        var statMax = StatValue(base: 50, min: 0, max: 100)
        statMax.current = 100
        statMax.clampToBounds()
        XCTAssertEqual(statMax.current, 100, accuracy: 0.001)
    }

    func testValueSemantics() {
        var original = StatValue(base: 50)
        var copy = original
        copy.current = 999
        XCTAssertEqual(original.current, 50, accuracy: 0.001)
    }
}
