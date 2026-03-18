//
//  RoomComponentTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 19/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class RoomComponentTests: XCTestCase {
 
    // MARK: - Computed properties
 
    func test_center_isMiddleOfBounds() {
        let bounds = RoomBounds(origin: SIMD2(0, 0), size: SIMD2(200, 100))
        XCTAssertEqual(bounds.center.x, 100)
        XCTAssertEqual(bounds.center.y, 50)
    }
 
    func test_center_withNegativeOrigin() {
        let bounds = RoomBounds(origin: SIMD2(-100, -50), size: SIMD2(200, 100))
        XCTAssertEqual(bounds.center.x, 0)
        XCTAssertEqual(bounds.center.y, 0)
    }
 
    func test_max_isOriginPlusSize() {
        let bounds = RoomBounds(origin: SIMD2(10, 20), size: SIMD2(300, 400))
        XCTAssertEqual(bounds.max.x, 310)
        XCTAssertEqual(bounds.max.y, 420)
    }
 
    // MARK: - contains
 
    func test_contains_centerPoint_returnsTrue() {
        let bounds = RoomBounds(origin: SIMD2(-100, -100), size: SIMD2(200, 200))
        XCTAssertTrue(bounds.contains(SIMD2(0, 0)))
    }
 
    func test_contains_originPoint_returnsTrue() {
        let bounds = RoomBounds(origin: SIMD2(-100, -100), size: SIMD2(200, 200))
        XCTAssertTrue(bounds.contains(SIMD2(-100, -100)))
    }
 
    func test_contains_maxPoint_returnsTrue() {
        let bounds = RoomBounds(origin: SIMD2(-100, -100), size: SIMD2(200, 200))
        XCTAssertTrue(bounds.contains(SIMD2(100, 100)))
    }
 
    func test_contains_pointJustOutsideLeft_returnsFalse() {
        let bounds = RoomBounds(origin: SIMD2(-100, -100), size: SIMD2(200, 200))
        XCTAssertFalse(bounds.contains(SIMD2(-100.1, 0)))
    }
 
    func test_contains_pointJustOutsideBottom_returnsFalse() {
        let bounds = RoomBounds(origin: SIMD2(-100, -100), size: SIMD2(200, 200))
        XCTAssertFalse(bounds.contains(SIMD2(0, -100.1)))
    }
 
    func test_contains_pointFarOutside_returnsFalse() {
        let bounds = RoomBounds(origin: SIMD2(0, 0), size: SIMD2(100, 100))
        XCTAssertFalse(bounds.contains(SIMD2(999, 999)))
    }
 
    // MARK: - randomPosition
 
    func test_randomPosition_isWithinBoundsMinusMargin() {
        let bounds = RoomBounds(origin: SIMD2(-200, -200), size: SIMD2(400, 400))
        let margin: Float = 50
 
        // Run multiple times to catch any edge failures from randomness
        for _ in 0..<50 {
            let pos = bounds.randomPosition(margin: margin)
            XCTAssertGreaterThanOrEqual(pos.x, bounds.origin.x + margin)
            XCTAssertLessThanOrEqual(pos.x,    bounds.max.x   - margin)
            XCTAssertGreaterThanOrEqual(pos.y, bounds.origin.y + margin)
            XCTAssertLessThanOrEqual(pos.y,    bounds.max.y   - margin)
        }
    }
 
    func test_randomPosition_defaultMargin_isWithinBounds() {
        let bounds = RoomBounds(origin: SIMD2(0, 0), size: SIMD2(500, 500))
        for _ in 0..<20 {
            let pos = bounds.randomPosition()
            XCTAssertTrue(bounds.contains(pos))
        }
    }
    
    // MARK: - Initialisation
 
    func test_init_defaultsToEmptyDoorwaysAndSpawnPoints() {
        let bounds = RoomBounds(origin: .zero, size: SIMD2(200, 200))
        let room = RoomComponent(bounds: bounds)
 
        XCTAssertTrue(room.doorways.isEmpty)
        XCTAssertTrue(room.spawnPoints.isEmpty)
        XCTAssertNil(room.gridLayout)
    }
 
    func test_init_assignsUniqueRoomIDs() {
        let bounds = RoomBounds(origin: .zero, size: SIMD2(200, 200))
        let roomA = RoomComponent(bounds: bounds)
        let roomB = RoomComponent(bounds: bounds)
        XCTAssertNotEqual(roomA.roomID, roomB.roomID)
    }
 
    func test_init_preservesDoorways() {
        let bounds = RoomBounds(origin: .zero, size: SIMD2(400, 400))
        let doorway = Doorway(position: SIMD2(200, 400), direction: .north)
        let room = RoomComponent(bounds: bounds, doorways: [doorway])
 
        XCTAssertEqual(room.doorways.count, 1)
        XCTAssertEqual(room.doorways[0].direction, .north)
    }
 
    func test_init_preservesSpawnPoints() {
        let bounds = RoomBounds(origin: .zero, size: SIMD2(400, 400))
        let spawn = SpawnPoint(position: SIMD2(200, 200), type: .playerEntry)
        let room = RoomComponent(bounds: bounds, spawnPoints: [spawn])
 
        XCTAssertEqual(room.spawnPoints.count, 1)
        XCTAssertEqual(room.spawnPoints[0].type, .playerEntry)
    }
 
    // MARK: - GridLayout
 
    func test_gridLayout_init_fillsAllTilesAsFloor() {
        let grid = GridLayout(gridSize: SIMD2(5, 4), cellSize: 32)
 
        XCTAssertEqual(grid.tiles.count, 4)          // rows = y
        XCTAssertEqual(grid.tiles[0].count, 5)       // cols = x
        for row in grid.tiles {
            for tile in row {
                XCTAssertEqual(tile, .floor)
            }
        }
    }
 
    func test_gridLayout_worldPosition_correctForOrigin() {
        let grid = GridLayout(gridSize: SIMD2(10, 10), cellSize: 32)
        let roomOrigin = SIMD2<Float>(0, 0)
 
        // Grid cell (0,0) world position should be offset by half a cell
        let pos = grid.worldPosition(gridX: 0, gridY: 0, roomOrigin: roomOrigin)
        XCTAssertEqual(pos.x, 16)   // 0 * 32 + 16
        XCTAssertEqual(pos.y, 16)
    }
 
    func test_gridLayout_worldPosition_correctForNonZeroCell() {
        let grid = GridLayout(gridSize: SIMD2(10, 10), cellSize: 32)
        let roomOrigin = SIMD2<Float>(-160, -160)
 
        let pos = grid.worldPosition(gridX: 2, gridY: 3, roomOrigin: roomOrigin)
        XCTAssertEqual(pos.x, -160 + 2 * 32 + 16, accuracy: 0.001)
        XCTAssertEqual(pos.y, -160 + 3 * 32 + 16, accuracy: 0.001)
    }
}
