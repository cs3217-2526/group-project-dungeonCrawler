import Foundation

/// Loads and caches `TileRegistryEntry` values decoded from the JSON files in Resources/Tilesets/.
///
/// This type is framework-only — no SpriteKit import. The concrete adapter uses the
/// decoded entries to build `SKTexture` objects and `SKTileSet` instances.
public final class TileRegistryLoader {

    private var cache: [TileTheme: TileRegistryEntry] = [:]

    public init() {}

    /// Returns the `TileRegistryEntry` for `theme`, loading and caching it on first call.
    /// Returns `nil` if the JSON file is missing or malformed.
    public func entry(for theme: TileTheme) -> TileRegistryEntry? {
        if let cached = cache[theme] { return cached }
        guard let entry = load(theme) else { return nil }
        cache[theme] = entry
        return entry
    }

    // MARK: - Private

    private func load(_ theme: TileTheme) -> TileRegistryEntry? {
        // Try root first, then the subdirectory path preserved by fileSystemSynchronizedGroups.
        let url = Bundle.main.url(forResource: theme.rawValue, withExtension: "json")
            ?? Bundle.main.url(forResource: theme.rawValue, withExtension: "json", subdirectory: "Tilesets")
            ?? Bundle.main.url(forResource: theme.rawValue, withExtension: "json", subdirectory: "Resources/Tilesets")
        guard let url else {
            print("[TileRegistryLoader]: Missing bundle resource: \(theme.rawValue).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let raw  = try JSONDecoder().decode(RawRegistry.self, from: data)
            return raw.toEntry()
        } catch {
            print("[TileRegistryLoader]: Failed to decode \(theme.rawValue).json: \(error)")
            return nil
        }
    }
}

// MARK: - Raw JSON Models (private)

private struct RawRegistry: Decodable {
    let meta: TileMeta
    let floor: RawFloor
    let wall: RawWall
    let barrier: RawBarrier?

    func toEntry() -> TileRegistryEntry {
        // Fallback barrier tiles (col 0, row 0) used when the JSON key is absent.
        let fallbackCoord = TileCoord(col: 0, row: 0)
        return TileRegistryEntry(
            meta: meta,
            floor:        [floor.plain, floor.variant1, floor.variant2,
                           floor.variant3, floor.variant4].compactMap { $0 },
            wallTopCap:   wall.top.capRow,
            wallTopFace:  wall.top.faceRow,
            wallTopFace2: wall.top.faceRow2 ?? wall.top.faceRow,
            wallTopBase:  wall.top.baseRow,
            wallBottom:   wall.bottom,
            wallLeft:     wall.left,
            wallRight:    wall.right,
            cornerTopLeft:     wall.corners.topLeft,
            cornerTopRight:    wall.corners.topRight,
            cornerBottomLeft:  wall.corners.bottomLeft,
            cornerBottomRight: wall.corners.bottomRight,
            floorDecoration:   floor.decorations ?? [],
            wallTopDecoration: wall.top.decorations ?? [],
            wallLeftFace:      wall.leftFace ?? [],
            wallRightFace:     wall.rightFace ?? [],
            barrierLeft:     barrier?.left     ?? fallbackCoord,
            barrierRight:    barrier?.right    ?? fallbackCoord,
            barrierVertical: barrier?.vertical ?? []
        )
    }
}

private struct RawBarrier: Decodable {
    let left:     TileCoord
    let right:    TileCoord
    let vertical: [TileCoord]
}

private struct RawFloor: Decodable {
    let plain:    TileCoord
    let variant1: TileCoord?
    let variant2: TileCoord?
    let variant3: TileCoord?
    let variant4: TileCoord?
    let decorations: [TileCoord]?
}

private struct RawWall: Decodable {
    let top:     RawWallTop
    let bottom:  [TileCoord]
    let left:    [TileCoord]
    let right:   [TileCoord]
    let corners: RawCorners
    let leftFace:  [TileCoord]?
    let rightFace: [TileCoord]?
}

private struct RawWallTop: Decodable {
    let capRow:  [TileCoord]
    let faceRow: [TileCoord]
    let faceRow2: [TileCoord]?
    let baseRow: [TileCoord]
    let decorations: [TileCoord]?
}

private struct RawCorners: Decodable {
    let topLeft:     TileCoord
    let topRight:    TileCoord
    let bottomLeft:  TileCoord
    let bottomRight: TileCoord
}
