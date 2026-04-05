import Foundation

// MARK: - Coordinate

/// A position in a sprite sheet, in tile-grid coordinates (col 0 = leftmost, row 0 = topmost).
public struct TileCoord: Codable, Equatable {
    public let col: Int
    public let row: Int
}

// MARK: - Theme

/// Identifies a dungeon visual theme. Each case maps to a JSON registry file in Resources/Tilesets/.
public enum TileTheme: String, CaseIterable {
    case chilling = "chilling_dungeon"
    case burning  = "burning_dungeon"
    case living   = "living_dungeon"
}

// MARK: - Registry Entry

/// The decoded, strongly-typed representation of one tileset JSON file.
/// All tile variants are exposed as arrays; the caller picks randomly for variety.
public struct TileRegistryEntry {
    public let meta: TileMeta

    // Floor — 1 plain + up to 4 variants
    public let floor: [TileCoord]

    // North (top) wall — 3 visual rows
    public let wallTopCap:  [TileCoord]
    public let wallTopFace: [TileCoord]
    public let wallTopFace2:      [TileCoord]
    public let wallTopBase: [TileCoord]

    // South (bottom), west (left), east (right) walls — variants
    public let wallBottom: [TileCoord]
    public let wallLeft:   [TileCoord]
    public let wallRight:  [TileCoord]

    // Room corners — single tiles, one per corner
    public let cornerTopLeft:     TileCoord
    public let cornerTopRight:    TileCoord
    public let cornerBottomLeft:  TileCoord
    public let cornerBottomRight: TileCoord

    // Decorations / Overlays (Optional)
    public let floorDecoration:   [TileCoord]
    public let wallTopDecoration: [TileCoord]
    public let wallLeftFace:      [TileCoord]
    public let wallRightFace:     [TileCoord]

    // Barriers — placed at locked room doorways
    public let barrierLeft:     TileCoord
    public let barrierRight:    TileCoord
    public let barrierVertical: [TileCoord]  // 4 elements ordered bottom-to-top

    /// Deterministically picks a random tile coordinate for the given role.
    public func randomCoord(for role: TileRole, using generator: inout SeededGenerator) -> TileCoord? {
        let pool: [TileCoord]?
        switch role {
        case .floor:             pool = floor
        case .wallTopCap:        pool = wallTopCap
        case .wallTopFace:       pool = wallTopFace
        case .wallTopFace2:      pool = wallTopFace2
        case .wallTopBase:       pool = wallTopBase
        case .wallBottom:        pool = wallBottom
        case .wallLeft:          pool = wallLeft
        case .wallRight:         pool = wallRight
        case .cornerTopLeft:     return cornerTopLeft
        case .cornerTopRight:    return cornerTopRight
        case .cornerBottomLeft:  return cornerBottomLeft
        case .cornerBottomRight: return cornerBottomRight
        case .floorDecoration:   pool = floorDecoration
        case .wallTopDecoration: pool = wallTopDecoration
        case .wallLeftFace:      pool = wallLeftFace
        case .wallRightFace:     pool = wallRightFace
        case .barrierLeft:       return barrierLeft
        case .barrierRight:      return barrierRight
        case .barrierVertical0:  return barrierVertical.indices.contains(0) ? barrierVertical[0] : nil
        case .barrierVertical1:  return barrierVertical.indices.contains(1) ? barrierVertical[1] : nil
        case .barrierVertical2:  return barrierVertical.indices.contains(2) ? barrierVertical[2] : nil
        case .barrierVertical3:  return barrierVertical.indices.contains(3) ? barrierVertical[3] : nil
        }

        guard let validPool = pool, !validPool.isEmpty else { return nil }
        return validPool.randomElement(using: &generator)
    }
}

// MARK: - Meta

public struct TileMeta: Codable {
    public let sheet:     String
    public let tileSize:  Int
    public let sheetCols: Int
    public let sheetRows: Int
}
