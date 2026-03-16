//
//  StatTypeTests.swift
//  dungeonCrawlerTests
//

import XCTest
@testable import dungeonCrawler

final class StatValueTests: XCTestCase {

    func testCurrentEqualsBaseOnInit() {
        let sv = StatValue(base: 50)
        XCTAssertEqual(sv.current, 50)
    }

    func testMinDefaultsToZero() {
        let sv = StatValue(base: 10)
        XCTAssertEqual(sv.min, 0)
    }

    func testMaxDefaultsToNil() {
        let sv = StatValue(base: 10)
        XCTAssertNil(sv.max)
    }

    func testExplicitMinAndMax() {
        let sv = StatValue(base: 50, min: 10, max: 100)
        XCTAssertEqual(sv.base, 50)
        XCTAssertEqual(sv.min, 10)
        XCTAssertEqual(sv.max, 100)
    }
}
