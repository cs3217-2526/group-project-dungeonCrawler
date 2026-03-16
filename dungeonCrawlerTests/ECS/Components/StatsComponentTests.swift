//
//  StatsComponentTests.swift
//  dungeonCrawlerTests
//

import XCTest
@testable import dungeonCrawler

final class StatsComponentTests: XCTestCase {

    func testValueForPresentStat() {
        let sc = StatsComponent(stats: [.health: StatValue(base: 100)])
        XCTAssertEqual(sc.value(for: .health)?.base, 100)
    }

    func testValueForAbsentStatReturnsNil() {
        let sc = StatsComponent()
        XCTAssertNil(sc.value(for: .attack))
    }

    func testMutatingCurrent() {
        let sc = StatsComponent(stats: [.health: StatValue(base: 100)])
        sc.stats[.health]?.current = 0
        XCTAssertEqual(sc.value(for: .health)?.current, 0)
    }
}
