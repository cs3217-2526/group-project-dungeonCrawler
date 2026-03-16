//
//  EntityTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 16/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler
 
final class EntityTests: XCTestCase {
    
    func testEntityCreation() {
        let entity = Entity()
        XCTAssertNotNil(entity.id)
    }
    
    func testEntityUniqueness() {
        let entity1 = Entity()
        let entity2 = Entity()
        XCTAssertNotEqual(entity1, entity2)
        XCTAssertNotEqual(entity1.id, entity2.id)
    }
    
    func testEntityEquality() {
        let entity1 = Entity()
        let entity2 = entity1
        XCTAssertEqual(entity1, entity2)
        XCTAssertEqual(entity1.id, entity2.id)
    }
    
    func testEntityHashable() {
        let entity1 = Entity()
        let entity2 = Entity()
        
        var set = Set<Entity>()
        set.insert(entity1)
        set.insert(entity2)
        
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(entity1))
        XCTAssertTrue(set.contains(entity2))
    }
    
    func testEntityInDictionary() {
        let entity1 = Entity()
        let entity2 = Entity()
        
        var dict = [Entity: String]()
        dict[entity1] = "First"
        dict[entity2] = "Second"
        
        XCTAssertEqual(dict[entity1], "First")
        XCTAssertEqual(dict[entity2], "Second")
        XCTAssertEqual(dict.count, 2)
    }
}
