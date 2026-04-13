import SpriteKit
import Foundation

// MARK: - Data model

/// The decoded character spritesheet: animation frame names + pre-extracted textures.
public struct CharacterSheet {
    /// Maps animation keys (e.g. "walkDown") to ordered texture-cache name arrays.
    public let animations: [String: [String]]
    /// Default per-frame display duration (seconds).
    public let frameDuration: Double
    /// All extracted sub-textures keyed by their cache name (e.g. "character_walkDown_0").
    public let textureRegistry: [String: SKTexture]
}

// MARK: - Loader

/// Reads `character.json`, loads the character PNG spritesheet, and pre-extracts every
/// animation frame into an `SKTexture` using the same UV-flip convention as the tile adapter.
public struct CharacterSheetLoader {

    public init() {}

    public func load() -> CharacterSheet? {
        guard let raw = decodeJSON() else { return nil }

        let sheetTexture = SKTexture(imageNamed: raw.meta.sheet)
        sheetTexture.filteringMode = .nearest

        let cols = CGFloat(raw.meta.sheetCols)
        let rows = CGFloat(raw.meta.sheetRows)
        let tileW = 1.0 / cols
        let tileH = 1.0 / rows

        var registry  = [String: SKTexture]()
        var animations = [String: [String]]()

        // Extract walk / idle animation frames
        for (animName, coords) in raw.animations {
            var names = [String]()
            for (idx, coord) in coords.enumerated() {
                let name    = "character_\(animName)_\(idx)"
                let texture = extractTexture(col: coord.col, row: coord.row,
                                             cols: cols, rows: rows, tileW: tileW, tileH: tileH,
                                             from: sheetTexture)
                registry[name] = texture
                names.append(name)
            }
            animations[animName] = names
        }

        // Extract soul frames (stored in registry under "character_soul_N")
        for (idx, coord) in raw.soul.frames.enumerated() {
            let name    = "character_soul_\(idx)"
            let texture = extractTexture(col: coord.col, row: coord.row,
                                         cols: cols, rows: rows, tileW: tileW, tileH: tileH,
                                         from: sheetTexture)
            registry[name] = texture
        }

        return CharacterSheet(
            animations:      animations,
            frameDuration:   raw.frameDuration,
            textureRegistry: registry
        )
    }

    // MARK: - Private

    private func extractTexture(
        col: Int, row: Int,
        cols: CGFloat, rows: CGFloat,
        tileW: CGFloat, tileH: CGFloat,
        from sheet: SKTexture
    ) -> SKTexture {
        let uvX  = CGFloat(col) / cols
        // Flip Y: row 0 = top of image, SpriteKit UV origin = bottom-left
        let uvY  = CGFloat(Int(rows) - row - 1) / rows
        let rect = CGRect(x: uvX, y: uvY, width: tileW, height: tileH)
        let tex  = SKTexture(rect: rect, in: sheet)
        tex.filteringMode = .nearest
        return tex
    }

    private func decodeJSON() -> RawCharacterSheet? {
        let url = Bundle.main.url(forResource: "character", withExtension: "json")
            ?? Bundle.main.url(forResource: "character", withExtension: "json", subdirectory: "Tilesets")
            ?? Bundle.main.url(forResource: "character", withExtension: "json", subdirectory: "Resources/Tilesets")
        guard let url else {
            print("[CharacterSheetLoader] character.json not found")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RawCharacterSheet.self, from: data)
        } catch {
            print("[CharacterSheetLoader] Failed to decode character.json: \(error)")
            return nil
        }
    }
}

// MARK: - Raw JSON models

private struct RawCharacterSheet: Decodable {
    let meta:          RawMeta
    let frameDuration: Double
    let animations:    [String: [TileCoord]]
    let soul:          RawSoul

    struct RawMeta: Decodable {
        let sheet:     String
        let tileSize:  Int
        let sheetCols: Int
        let sheetRows: Int
    }

    struct RawSoul: Decodable {
        let frames:        [TileCoord]
        let frameDuration: Double
    }
}
