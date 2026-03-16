//
//  EntityTests.swift
//  dungeonCrawlerTests
//

import XCTest
@testable import dungeonCrawler

final class EntityTests: XCTestCase {

    func testCreateEntity_AppearsInAllEntities() {
        let world = World()
        let entity = world.createEntity()
        XCTAssertTrue(world.allEntities.contains(entity))
    }

}
