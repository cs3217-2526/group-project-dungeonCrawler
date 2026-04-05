import Foundation

// MARK: - Tile Layer

/// The z-ordered rendering layer for a grid of tiles.
/// Layers are stacked from bottom to top by the renderer.
public enum TileLayer: CaseIterable {
    case floor
    case structural
    case decoration
    /// Foreground tiles that render above gameplay entities (e.g. south/bottom wall face).
    case overlay

    /// Provides a relative z-offset within the tilemap rendering space.
    /// Final SKTileMapNode z = -1.0 + zOffset.
    public var zOffset: Float {
        switch self {
        case .floor:      return 0.0
        case .structural: return 0.1
        case .decoration: return 0.2
        case .overlay:    return 7.5   // z = 6.5 — above entities (6), below weapons (7)
        }
    }
}

// MARK: - Tile Role

/// The semantic role of a single tile cell in a room or corridor grid.
/// The adapter maps each role to a concrete tile from the `TileRegistryEntry`.
public enum TileRole: Hashable {
    // Structural (Base layer usually)
    case floor

    // North (top) wall — 4 stacked rows, from top to bottom
    case wallTopCap     // crown / topmost visible row
    case wallTopFace    // brick facing row (upper)
    case wallTopFace2   // brick facing row (lower)
    case wallTopBase    // base trim row, just above the floor

    // South (bottom) wall — 1 tile high
    case wallBottom

    // Side walls
    case wallLeft
    case wallRight

    // Room corners — one per quadrant
    case cornerTopLeft
    case cornerTopRight
    case cornerBottomLeft
    case cornerBottomRight
    
    // Decorations / Overlays (Decoration layer)
    case floorDecoration
    case wallTopDecoration
    case wallLeftFace     // The vertical face of the left-side wall (placed to its right)
    case wallRightFace    // The vertical face of the right-side wall (placed to its left)

    // Barriers — rendered on the overlay layer at locked room doorways
    case barrierLeft       // West/left-side doorway of a horizontal corridor
    case barrierRight      // East/right-side doorway of a horizontal corridor
    case barrierVertical0  // Bottom row of a vertical corridor barrier
    case barrierVertical1
    case barrierVertical2
    case barrierVertical3  // Top row
}

// MARK: - Barrier Side

/// Which end of a corridor the barrier sits on. Determines tile selection and grid orientation.
public enum BarrierSide {
    case left   // West end of a horizontal corridor
    case right  // East end of a horizontal corridor
    case top    // North end of a vertical corridor
    case bottom // South end of a vertical corridor
}

// MARK: - Tile Painter

/// Pure-function tile assignment: converts geometric room/corridor descriptions into a
/// 2-D grid of `TileRole?` values (nil = leave cell empty / transparent).
///
/// No SpriteKit dependency — the grid is consumed by `SpriteKitTileMapAdapter` which
/// maps each role to the appropriate `SKTileGroup`.
public enum TilePainter {

    // MARK: - Room

    /// Returns a `rows × cols` grid (`grid[row][col]`) of tile roles for a room.
    ///
    /// - Parameters:
    ///   - cols: Number of tile columns (`ceil(bounds.width / tileSize)`).
    ///   - rows: Number of tile rows (`ceil(bounds.height / tileSize)`).
    ///   - bounds: Room world-space bounds (used for doorway gap calculation).
    ///   - doorways: Doorways that cut openings in the perimeter walls.
    ///   - tileSize: World units per tile (e.g. 16).
    public static func paint(
        cols: Int,
        rows: Int,
        bounds: RoomBounds,
        doorways: [Doorway],
        tileSize: Float,
        using generator: inout SeededGenerator
    ) -> [TileLayer: [[TileRole?]]] {
        var layers: [TileLayer: [[TileRole?]]] = [
            .floor: Array(repeating: Array(repeating: nil, count: cols), count: rows),
            .structural: Array(repeating: Array(repeating: nil, count: cols), count: rows),
            .decoration: Array(repeating: Array(repeating: nil, count: cols), count: rows),
            .overlay: Array(repeating: Array(repeating: nil, count: cols), count: rows)
        ]

        guard cols >= 2, rows >= 5 else {
            // Room too small to paint meaningfully — fill with floor
            for r in 0..<rows { for c in 0..<cols { layers[.floor]![r][c] = .floor } }
            return layers
        }

        // Pre-compute doorway gap sets (tile indices where wall must be cleared)
        let northGaps = columnGaps(
            doorways: doorways.filter { $0.direction == .north },
            bounds: bounds, tileSize: tileSize, maxIndex: cols - 1
        )
        let southGaps = columnGaps(
            doorways: doorways.filter { $0.direction == .south },
            bounds: bounds, tileSize: tileSize, maxIndex: cols - 1
        )
        let westGaps = rowGaps(
            doorways: doorways.filter { $0.direction == .west },
            bounds: bounds, tileSize: tileSize, maxIndex: rows - 1
        )
        let eastGaps = rowGaps(
            doorways: doorways.filter { $0.direction == .east },
            bounds: bounds, tileSize: tileSize, maxIndex: rows - 1
        )

        // The top wall occupies the topmost rows defined by WorldConstants.
        // Side walls occupy col 0 and col cols-1 for rows below the top wall zone.
        // Bottom wall occupies row 0 for cols 1 through cols-2.
        // Corners occupy the 4 extreme cells.
        // Everything else is floor.

        let topWallStart = rows - WorldConstants.topWallHeightTiles   // row index where top wall zone begins

        // The floor layer is always a solid bed.
        for r in 0..<rows { for c in 0..<cols { layers[.floor]![r][c] = .floor } }

        for row in 0..<rows {
            for col in 0..<cols {

                // -- Corners (take precedence over everything) --
                // Top corners stay on the structural layer (rendered below entities).
                // Bottom corners go on the overlay layer so they appear in front of the player.
                if row == rows - 1 && col == 0          { layers[.structural]![row][col] = .cornerTopLeft;     continue }
                if row == rows - 1 && col == cols - 1   { layers[.structural]![row][col] = .cornerTopRight;    continue }
                if row == 0        && col == 0          { layers[.overlay]![row][col]     = .cornerBottomLeft;  continue }
                if row == 0        && col == cols - 1   { layers[.overlay]![row][col]     = .cornerBottomRight; continue }

                // -- Top wall zone (rows topWallStart … rows-1, inner cols only) --
                if row >= topWallStart && col > 0 && col < cols - 1 {
                    if !northGaps.contains(col) {
                        switch rows - 1 - row {   // distance from top edge
                        case 0:
                            layers[.structural]![row][col] = .wallTopCap
                            layers[.decoration]![row][col] = .wallTopDecoration
                        case 1: layers[.structural]![row][col] = .wallTopFace2 // row 1 in atlas
                        case 2: layers[.structural]![row][col] = .wallTopFace  // row 2 in atlas
                        case 3: layers[.structural]![row][col] = .wallTopBase  // row 3 in atlas
                        default: layers[.structural]![row][col] = .wallTopBase
                        }
                    }
                    continue
                }

                // -- Bottom wall (row 0, inner cols) --
                // Placed on the overlay layer so it renders in front of the player.
                if row == 0 && col > 0 && col < cols - 1 {
                    if !southGaps.contains(col) {
                        layers[.overlay]![row][col] = .wallBottom
                    }
                    continue
                }

                // -- Left wall (col 0, rows 1 … topWallStart-1) --
                if col == 0 && row > 0 && row < topWallStart {
                    if !westGaps.contains(row) {
                        layers[.structural]![row][col] = .wallLeft
                        layers[.decoration]![row][col + 1] = .wallLeftFace
                    }
                    continue
                }

                // -- Right wall (col cols-1, rows 1 … topWallStart-1) --
                if col == cols - 1 && row > 0 && row < topWallStart {
                    if !eastGaps.contains(row) {
                        layers[.structural]![row][col] = .wallRight
                        layers[.decoration]![row][col - 1] = .wallRightFace
                    }
                    continue
                }

                // -- Fill left/right wall columns inside the top wall zone with side wall --
                if col == 0 && row >= topWallStart {
                    layers[.structural]![row][col] = .wallLeft
                    layers[.decoration]![row][col + 1] = .wallLeftFace
                    continue
                }
                if col == cols - 1 && row >= topWallStart {
                    layers[.structural]![row][col] = .wallRight
                    layers[.decoration]![row][col - 1] = .wallRightFace
                    continue
                }
                
                // Add some optional floor decorations sporadically in the free space
                if layers[.structural]![row][col] == nil && Float.random(in: 0...1, using: &generator) > 0.95 {
                    layers[.decoration]![row][col] = .floorDecoration
                }
            }
        }

        return layers
    }

    // MARK: - Corridor

    /// Returns a tile role grid for a corridor segment.
    ///
    /// Horizontal corridors use the same 3-row top-wall structure as rooms (cap/face/base)
    /// plus a 1-row bottom wall. Vertical corridors use left/right side walls.
    /// Corners are placed at all four extremities.
    ///
    /// - Parameters:
    ///   - cols: Number of tile columns.
    ///   - rows: Number of tile rows.
    ///   - axis: `.horizontal` (top/bottom walls) or `.vertical` (left/right walls).
    public static func paintCorridor(cols: Int, rows: Int, axis: CorridorAxis, using generator: inout SeededGenerator) -> [TileLayer: [[TileRole?]]] {
        var layers: [TileLayer: [[TileRole?]]] = [
            .floor: Array(repeating: Array(repeating: nil, count: cols), count: rows),
            .structural: Array(repeating: Array(repeating: nil, count: cols), count: rows),
            .decoration: Array(repeating: Array(repeating: nil, count: cols), count: rows),
            .overlay: Array(repeating: Array(repeating: nil, count: cols), count: rows)
        ]

        guard cols >= 2, rows >= 2 else {
            for r in 0..<rows { for c in 0..<cols { layers[.floor]![r][c] = .floor } }
            return layers
        }

        for r in 0..<rows { for c in 0..<cols { layers[.floor]![r][c] = .floor } }

        switch axis {
        case .horizontal:
            // Top wall occupies the topmost 4 rows (same structure as rooms).
            let topWallStart = max(1, rows - 4)

            for row in 0..<rows {
                for col in 0..<cols {
                    // Corners — bottom corners go on overlay so they render in front of the player.
                    if row == rows - 1 && col == 0          { layers[.structural]![row][col] = .cornerTopLeft;     continue }
                    if row == rows - 1 && col == cols - 1   { layers[.structural]![row][col] = .cornerTopRight;    continue }
                    if row == 0        && col == 0          { layers[.overlay]![row][col]     = .cornerBottomLeft;  continue }
                    if row == 0        && col == cols - 1   { layers[.overlay]![row][col]     = .cornerBottomRight; continue }

                    // Top wall
                    if row >= topWallStart {
                        switch rows - 1 - row {
                        case 0:
                            layers[.structural]![row][col] = .wallTopCap
                            layers[.decoration]![row][col] = .wallTopDecoration
                        case 1: layers[.structural]![row][col] = .wallTopFace2
                        case 2: layers[.structural]![row][col] = .wallTopFace
                        case 3: layers[.structural]![row][col] = .wallTopBase
                        default: layers[.structural]![row][col] = .wallTopBase
                        }
                        continue
                    }

                    // Bottom wall overlay so it renders in front of the player.
                    if row == 0 { layers[.overlay]![row][col] = .wallBottom; continue }
                }
            }

        case .vertical:
            for row in 0..<rows {
                for col in 0..<cols {
                    // Corners
                    if row == rows - 1 && col == 0          { layers[.structural]![row][col] = .cornerTopLeft;     continue }
                    if row == rows - 1 && col == cols - 1   { layers[.structural]![row][col] = .cornerTopRight;    continue }
                    if row == 0        && col == 0          { layers[.structural]![row][col] = .cornerBottomLeft;  continue }
                    if row == 0        && col == cols - 1   { layers[.structural]![row][col] = .cornerBottomRight; continue }

                    // Side walls
                    if col == 0 {
                        layers[.structural]![row][col] = .wallLeft
                        layers[.decoration]![row][col + 1] = .wallLeftFace
                        continue
                    }
                    if col == cols - 1 {
                        layers[.structural]![row][col] = .wallRight
                        layers[.decoration]![row][col - 1] = .wallRightFace
                        continue
                    }
                }
            }
        }

        return layers
    }

    // MARK: - Gap Helpers

    /// Returns the set of tile column indices that fall within a horizontal doorway opening.
    private static func columnGaps(
        doorways: [Doorway],
        bounds: RoomBounds,
        tileSize: Float,
        maxIndex: Int
    ) -> Set<Int> {
        var gaps = Set<Int>()
        for d in doorways {
            let relX   = d.position.x - bounds.minX
            let start  = Int(floor((relX - d.width / 2) / tileSize))
            let end    = Int(ceil((relX + d.width / 2) / tileSize)) - 1
            for c in max(0, start)...min(maxIndex, end) { gaps.insert(c) }
        }
        return gaps
    }

    /// Returns the set of tile row indices that fall within a vertical doorway opening.
    private static func rowGaps(
        doorways: [Doorway],
        bounds: RoomBounds,
        tileSize: Float,
        maxIndex: Int
    ) -> Set<Int> {
        var gaps = Set<Int>()
        for d in doorways {
            let relY   = d.position.y - bounds.minY
            let start  = Int(floor((relY - d.width / 2) / tileSize))
            let end    = Int(ceil((relY + d.width / 2) / tileSize)) - 1
            for r in max(0, start)...min(maxIndex, end) { gaps.insert(r) }
        }
        return gaps
    }

    // MARK: - Barrier

    /// Returns a 2-D `[[TileRole?]]` grid for a barrier strip at a corridor doorway.
    ///
    /// - For `.left` / `.right` sides (horizontal corridor): 1 col × `rows` rows,
    ///   all cells filled with `barrierLeft` or `barrierRight`.
    /// - For `.top` / `.bottom` sides (vertical corridor): `cols` cols × 4 rows,
    ///   each row filled with the matching `barrierVertical0–3` role (bottom → top).
    public static func paintBarrier(cols: Int, rows: Int, side: BarrierSide) -> [[TileRole?]] {
        var grid = Array(repeating: Array(repeating: Optional<TileRole>.none, count: cols), count: rows)
        switch side {
        case .left:
            for r in 0..<rows { grid[r][0] = .barrierLeft }
        case .right:
            for r in 0..<rows { grid[r][0] = .barrierRight }
        case .bottom, .top:
            let verticalRoles: [TileRole] = [.barrierVertical0, .barrierVertical1, .barrierVertical2, .barrierVertical3]
            let rowCount = min(rows, verticalRoles.count)
            for r in 0..<rowCount {
                for c in 0..<cols { grid[r][c] = verticalRoles[r] }
            }
        }
        return grid
    }
}
