import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class TilePainterTests: XCTestCase {

    // MARK: - Constants matching WorldConstants

    private let tileSize: Float = 16.0
    private let topWallHeight = 4   // WorldConstants.topWallHeightTiles

    // Test room: 10 cols × 10 rows (160 × 160 world units).
    private let cols = 10
    private let rows = 10
    private var bounds: RoomBounds { RoomBounds(origin: .zero, size: SIMD2(160, 160)) }
    private var rng: SeededGenerator { SeededGenerator(seed: 42) }

    // MARK: - Pre-built doorway fixtures

    var northDoorway: Doorway!   // center north, width 64 → gap cols 3–6
    var southDoorway: Doorway!   // center south, width 64 → gap cols 3–6

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        northDoorway = Doorway(position: SIMD2(80, 160), direction: .north, width: 64)
        southDoorway = Doorway(position: SIMD2(80, 0),   direction: .south, width: 64)
    }

    override func tearDown() {
        northDoorway = nil
        southDoorway = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func paint(doorways: [Doorway] = []) -> [TileLayer: [[TileRole?]]] {
        var g = rng
        return TilePainter.paint(cols: cols, rows: rows, bounds: bounds,
                                  doorways: doorways, tileSize: tileSize, using: &g)
    }

    private func paintCorridor(cols: Int, rows: Int, axis: CorridorAxis) -> [TileLayer: [[TileRole?]]] {
        var g = rng
        return TilePainter.paintCorridor(cols: cols, rows: rows, axis: axis, using: &g)
    }

    // MARK: - Layer presence

    func testPaintReturnsAllFourLayers() {
        let layers = paint()
        XCTAssertNotNil(layers[.floor])
        XCTAssertNotNil(layers[.structural])
        XCTAssertNotNil(layers[.decoration])
        XCTAssertNotNil(layers[.overlay])
    }

    func testLayersHaveCorrectDimensions() {
        let layers = paint()
        for layer in TileLayer.allCases {
            let grid = layers[layer]!
            XCTAssertEqual(grid.count, rows, "Row count wrong for layer \(layer)")
            XCTAssertTrue(grid.allSatisfy { $0.count == cols },
                          "Column count wrong for layer \(layer)")
        }
    }

    // MARK: - Floor layer

    func testFloorLayerIsFullyPopulated() {
        let floor = paint()[.floor]!
        for r in 0..<rows {
            for c in 0..<cols {
                XCTAssertEqual(floor[r][c], .floor, "Missing floor at (\(r), \(c))")
            }
        }
    }

    // MARK: - Corners

    func testTopLeftCornerPlacedInStructuralLayer() {
        let structural = paint()[.structural]!
        XCTAssertEqual(structural[rows - 1][0], .cornerTopLeft)
    }

    func testTopRightCornerPlacedInStructuralLayer() {
        let structural = paint()[.structural]!
        XCTAssertEqual(structural[rows - 1][cols - 1], .cornerTopRight)
    }

    func testBottomLeftCornerPlacedInOverlayLayer() {
        let overlay = paint()[.overlay]!
        XCTAssertEqual(overlay[0][0], .cornerBottomLeft)
    }

    func testBottomRightCornerPlacedInOverlayLayer() {
        let overlay = paint()[.overlay]!
        XCTAssertEqual(overlay[0][cols - 1], .cornerBottomRight)
    }

    // MARK: - Top wall (north)

    func testTopWallCapAppearsAtTopOfWallZone() {
        let structural = paint()[.structural]!
        for c in 1..<(cols - 1) {
            XCTAssertEqual(structural[rows - 1][c], .wallTopCap,
                           "Expected wallTopCap at col \(c)")
        }
    }

    func testTopWallInnerRowsHaveWallTiles() {
        let structural = paint()[.structural]!
        let topWallStart = rows - topWallHeight
        for r in topWallStart..<(rows - 1) {
            for c in 1..<(cols - 1) {
                XCTAssertNotNil(structural[r][c], "Expected wall tile at row \(r) col \(c)")
            }
        }
    }

    // MARK: - Bottom wall (south)

    func testBottomWallAppearsInOverlayForInnerCols() {
        let overlay = paint()[.overlay]!
        for c in 1..<(cols - 1) {
            XCTAssertEqual(overlay[0][c], .wallBottom,
                           "Expected wallBottom at col \(c)")
        }
    }

    // MARK: - Side walls

    func testLeftWallAppearsInStructuralLayer() {
        let structural = paint()[.structural]!
        let topWallStart = rows - topWallHeight
        for r in 1..<topWallStart {
            XCTAssertEqual(structural[r][0], .wallLeft,
                           "Expected wallLeft at row \(r)")
        }
    }

    func testRightWallAppearsInStructuralLayer() {
        let structural = paint()[.structural]!
        let topWallStart = rows - topWallHeight
        for r in 1..<topWallStart {
            XCTAssertEqual(structural[r][cols - 1], .wallRight,
                           "Expected wallRight at row \(r)")
        }
    }

    // MARK: - North doorway gap

    func testNorthDoorwayCreatesGapInTopWall() {
        let structural = paint(doorways: [northDoorway])[.structural]!

        for c in 3...6 {
            XCTAssertNil(structural[rows - 1][c],
                         "Expected gap at col \(c) in north wall")
        }
        for c in [1, 2, 7, 8] {
            XCTAssertNotNil(structural[rows - 1][c],
                            "Expected wall at col \(c) outside north doorway")
        }
    }

    // MARK: - South doorway gap

    func testSouthDoorwayCreatesGapInBottomWall() {
        let overlay = paint(doorways: [southDoorway])[.overlay]!

        for c in 3...6 {
            XCTAssertNil(overlay[0][c],
                         "Expected gap at col \(c) in south wall")
        }
        for c in [1, 2, 7, 8] {
            XCTAssertEqual(overlay[0][c], .wallBottom,
                           "Expected wallBottom at col \(c) outside south doorway")
        }
    }

    // MARK: - Small room fallback

    func testRoomTooSmallReturnsFallbackFloorOnly() {
        var g = rng
        let layers = TilePainter.paint(cols: 4, rows: 3, bounds: bounds,
                                        doorways: [], tileSize: tileSize, using: &g)
        let floor = layers[.floor]!
        XCTAssertTrue(floor.allSatisfy { row in row.allSatisfy { $0 == .floor } })
    }

    // MARK: - Corridor: horizontal

    func testHorizontalCorridorHasTopWallTiles() {
        let layers = paintCorridor(cols: 8, rows: 6, axis: .horizontal)
        let structural = layers[.structural]!
        for c in 0..<8 {
            XCTAssertNotNil(structural[5][c])
        }
    }

    func testHorizontalCorridorHasBottomWallInOverlay() {
        let layers = paintCorridor(cols: 8, rows: 6, axis: .horizontal)
        let overlay = layers[.overlay]!
        for c in 0..<8 {
            XCTAssertNotNil(overlay[0][c])
        }
    }

    // MARK: - Corridor: vertical

    func testVerticalCorridorHasLeftAndRightWalls() {
        let corridorCols = 4
        let corridorRows = 8
        let layers = paintCorridor(cols: corridorCols, rows: corridorRows, axis: .vertical)
        let structural = layers[.structural]!
        for r in 1..<(corridorRows - 1) {
            XCTAssertEqual(structural[r][0], .wallLeft,
                           "Expected wallLeft at row \(r)")
            XCTAssertEqual(structural[r][corridorCols - 1], .wallRight,
                           "Expected wallRight at row \(r)")
        }
    }

    // MARK: - paintBarrier

    func testBarrierLeftFillsFirstColumn() {
        let grid = TilePainter.paintBarrier(cols: 1, rows: 5, side: .left)
        for r in 0..<5 {
            XCTAssertEqual(grid[r][0], .barrierLeft, "Expected barrierLeft at row \(r)")
        }
    }

    func testBarrierRightFillsFirstColumn() {
        let grid = TilePainter.paintBarrier(cols: 1, rows: 5, side: .right)
        for r in 0..<5 {
            XCTAssertEqual(grid[r][0], .barrierRight, "Expected barrierRight at row \(r)")
        }
    }

    func testBarrierTopFillsVerticalRoles() {
        let grid = TilePainter.paintBarrier(cols: 3, rows: 4, side: .top)
        let expected: [TileRole] = [.barrierVertical0, .barrierVertical1,
                                     .barrierVertical2, .barrierVertical3]
        for r in 0..<4 {
            for c in 0..<3 {
                XCTAssertEqual(grid[r][c], expected[r],
                               "Expected \(expected[r]) at row \(r) col \(c)")
            }
        }
    }

    func testBarrierBottomFillsVerticalRoles() {
        let grid = TilePainter.paintBarrier(cols: 2, rows: 4, side: .bottom)
        XCTAssertEqual(grid[0][0], .barrierVertical0)
        XCTAssertEqual(grid[3][0], .barrierVertical3)
    }
}
