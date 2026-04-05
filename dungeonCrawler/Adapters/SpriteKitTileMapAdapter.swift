import SpriteKit
import Foundation

/// Concrete `TileMapRenderer` that renders dungeon backgrounds using `SKTileMapNode`.
///
/// One `SKTileMapNode` is created per room / corridor and added as a child of `worldLayer`
/// at z = -1 (below all gameplay sprites). Random tile variants are picked at placement
/// time via `setTileGroup(_:andTileDefinition:forColumn:row:)`.
///
/// All SpriteKit-specific code lives here. The protocol, tile painter, and registry loader
/// are all framework-layer types with no SpriteKit dependency.
public final class SpriteKitTileMapAdapter: TileMapRenderer {

    // MARK: - Dependencies

    private weak var worldLayer: SKNode?
    private let registryLoader: TileRegistryLoader

    // MARK: - Caches

    private var tileSetCache: [TileTheme: TileCache] = [:]
    private var tileMaps:     [UUID: [SKTileMapNode]] = [:]
    /// Barrier tile map nodes: roomID key that owns room barrier.
    private var barrierMaps:  [UUID: [SKTileMapNode]] = [:]

    private struct TileCache {
        let set:     SKTileSet
        let roleMap: [TileRole: TileGroupEntry]
    }

    private struct TileGroupEntry {
        let group: SKTileGroup
        let defs:  [SKTileDefinition]   // stored separately for random pick
    }

    // MARK: - Init

    public init(worldLayer: SKNode, registryLoader: TileRegistryLoader) {
        self.worldLayer     = worldLayer
        self.registryLoader = registryLoader
    }

    // MARK: - TileMapRenderer

    public func renderRoom(
        roomID:   UUID,
        bounds:   RoomBounds,
        doorways: [Doorway],
        theme:    TileTheme,
        using generator: inout SeededGenerator
    ) {
        guard let entry = registryLoader.entry(for: theme) else { return }
        let tileSize = Float(entry.meta.tileSize)
        let cols = Int(ceil(bounds.size.x / tileSize))
        let rows = Int(ceil(bounds.size.y / tileSize))
        guard cols >= 1, rows >= 1 else { return }

        let grids = TilePainter.paint(
            cols: cols, rows: rows,
            bounds: bounds, doorways: doorways,
            tileSize: tileSize,
            using: &generator
        )
        
        performRender(roomID: roomID, bounds: bounds, grids: grids, theme: theme, using: &generator)
    }

    public func renderCorridor(
        roomID: UUID,
        bounds: RoomBounds,
        axis:   CorridorAxis,
        theme:  TileTheme,
        using generator: inout SeededGenerator
    ) {
        let entry = registryLoader.entry(for: theme)
        let tileSize = Float(entry?.meta.tileSize ?? 16)
        let cols = max(1, Int(ceil(bounds.size.x / tileSize)))
        let rows = max(1, Int(ceil(bounds.size.y / tileSize)))

        let grids = TilePainter.paintCorridor(cols: cols, rows: rows, axis: axis, using: &generator)
        
        performRender(roomID: roomID, bounds: bounds, grids: grids, theme: theme, using: &generator)
    }

    /// Internal orchestrator that converts abstract grids into physical SKTileMapNodes.
    private func performRender(
        roomID: UUID,
        bounds: RoomBounds,
        grids:  [TileLayer: [[TileRole?]]],
        theme:  TileTheme,
        using generator: inout SeededGenerator
    ) {
        guard let worldLayer,
              let entry = registryLoader.entry(for: theme),
              let cache = buildCacheIfNeeded(theme: theme, entry: entry)
        else { return }

        let tileSize = entry.meta.tileSize
        let cols = Int(ceil(bounds.size.x / Float(tileSize)))
        let rows = Int(ceil(bounds.size.y / Float(tileSize)))

        for (layer, grid) in grids {
            let tileMap = makeTileMap(cache: cache, cols: cols, rows: rows, tileSize: tileSize, zOffset: layer.zOffset)
            tileMap.position = CGPoint(x: CGFloat(bounds.center.x), y: CGFloat(bounds.center.y))
            
            fillTileMap(tileMap, grid: grid, cache: cache, using: &generator)
            
            worldLayer.addChild(tileMap)
            tileMaps[roomID, default: []].append(tileMap)
        }
    }

    /// Removes all visual tile maps associated with a specific room ID.
    public func tearDownRoom(roomID: UUID) {
        tileMaps[roomID]?.forEach { $0.removeFromParent() }
        tileMaps.removeValue(forKey: roomID)
    }

    // MARK: - TileMapRenderer — Barriers

    public func renderBarrier(
        roomID: UUID,
        bounds: RoomBounds,
        side:   BarrierSide,
        theme:  TileTheme,
        using generator: inout SeededGenerator
    ) {
        guard let worldLayer,
              let entry = registryLoader.entry(for: theme),
              let cache = buildCacheIfNeeded(theme: theme, entry: entry)
        else { return }

        let tileSize = entry.meta.tileSize
        let cols = max(1, Int(ceil(bounds.size.x / Float(tileSize))))
        let rows = max(1, Int(ceil(bounds.size.y / Float(tileSize))))

        let grid = TilePainter.paintBarrier(cols: cols, rows: rows, side: side)

        let tileMap = makeTileMap(cache: cache, cols: cols, rows: rows, tileSize: tileSize, zOffset: TileLayer.overlay.zOffset)
        tileMap.position = CGPoint(x: CGFloat(bounds.center.x), y: CGFloat(bounds.center.y))
        fillTileMap(tileMap, grid: grid, cache: cache, using: &generator)

        worldLayer.addChild(tileMap)
        barrierMaps[roomID, default: []].append(tileMap)
    }

    public func tearDownBarriers(roomID: UUID) {
        barrierMaps[roomID]?.forEach { $0.removeFromParent() }
        barrierMaps.removeValue(forKey: roomID)
    }

    public func tearDownAll() {
        tileMaps.keys.forEach { tearDownRoom(roomID: $0) }
        barrierMaps.keys.forEach { tearDownBarriers(roomID: $0) }
    }

    // MARK: - Private — Tile map helpers

    private func makeTileMap(cache: TileCache, cols: Int, rows: Int, tileSize: Int, zOffset: Float) -> SKTileMapNode {
        let cgTileSize = CGSize(width: tileSize, height: tileSize)
        let tileMap = SKTileMapNode(
            tileSet: cache.set,
            columns: cols, rows: rows,
            tileSize: cgTileSize
        )
        // Base tilemaps map to -1.0, plus the specific layer's relative offset.
        tileMap.zPosition = CGFloat(-1.0 + zOffset)
        return tileMap
    }

    private func fillTileMap(_ tileMap: SKTileMapNode, grid: [[TileRole?]], cache: TileCache, using generator: inout SeededGenerator) {
        for (row, rowData) in grid.enumerated() {
            for (col, role) in rowData.enumerated() {
                guard let role,
                      let entry = cache.roleMap[role],
                      !entry.defs.isEmpty
                else { continue }
                
                // Pick a tile definition randomly using the SeededGenerator
                let def = entry.defs.randomElement(using: &generator) ?? entry.defs[0]
                tileMap.setTileGroup(entry.group, andTileDefinition: def, forColumn: col, row: row)
            }
        }
    }

    // MARK: - Private — TileSet construction

    private func buildCacheIfNeeded(theme: TileTheme, entry: TileRegistryEntry) -> TileCache? {
        if let cached = tileSetCache[theme] { return cached }

        let sheetTexture = SKTexture(imageNamed: entry.meta.sheet)
        sheetTexture.filteringMode = .nearest

        let sheetCols = CGFloat(entry.meta.sheetCols)
        let sheetRows = CGFloat(entry.meta.sheetRows)
        let tilePoints = CGSize(width: CGFloat(entry.meta.tileSize), height: CGFloat(entry.meta.tileSize))

        var mapping: [(TileRole, [TileCoord])] = [
            (.floor,             entry.floor),
            (.wallTopCap,        entry.wallTopCap),
            (.wallTopFace,       entry.wallTopFace),
            (.wallTopFace2,      entry.wallTopFace2),
            (.wallTopBase,       entry.wallTopBase),
            (.wallBottom,        entry.wallBottom),
            (.wallLeft,          entry.wallLeft),
            (.wallRight,         entry.wallRight),
            (.cornerTopLeft,     [entry.cornerTopLeft]),
            (.cornerTopRight,    [entry.cornerTopRight]),
            (.cornerBottomLeft,  [entry.cornerBottomLeft]),
            (.cornerBottomRight, [entry.cornerBottomRight]),
            (.floorDecoration,   entry.floorDecoration),
            (.wallTopDecoration, entry.wallTopDecoration),
            (.wallLeftFace,      entry.wallLeftFace),
            (.wallRightFace,     entry.wallRightFace),
        ]

        if let bl = entry.barrierLeft  { mapping.append((.barrierLeft,  [bl])) }
        if let br = entry.barrierRight { mapping.append((.barrierRight, [br])) }
        
        mapping.append(contentsOf: [
            (.barrierVertical0,  entry.barrierVertical.indices.contains(0) ? [entry.barrierVertical[0]] : []),
            (.barrierVertical1,  entry.barrierVertical.indices.contains(1) ? [entry.barrierVertical[1]] : []),
            (.barrierVertical2,  entry.barrierVertical.indices.contains(2) ? [entry.barrierVertical[2]] : []),
            (.barrierVertical3,  entry.barrierVertical.indices.contains(3) ? [entry.barrierVertical[3]] : []),
        ])

        var roleMap:   [TileRole: TileGroupEntry] = [:]
        var allGroups: [SKTileGroup]              = []

        for (role, coords) in mapping {
            guard !coords.isEmpty else { continue }
            
            let definitions = createTileDefinitions(
                coords: coords,
                texture: sheetTexture,
                cols: sheetCols,
                rows: sheetRows,
                tileSize: tilePoints
            )
            
            let group = createTileGroup(definitions: definitions)
            roleMap[role] = TileGroupEntry(group: group, defs: definitions)
            allGroups.append(group)
        }

        let tileSet = SKTileSet(tileGroups: allGroups)
        let cache   = TileCache(set: tileSet, roleMap: roleMap)
        tileSetCache[theme] = cache
        return cache
    }

    private func createTileDefinitions(
        coords: [TileCoord],
        texture: SKTexture,
        cols: CGFloat,
        rows: CGFloat,
        tileSize: CGSize
    ) -> [SKTileDefinition] {
        let tileW = 1.0 / cols
        let tileH = 1.0 / rows
        
        return coords.map { coord in
            let uvX = CGFloat(coord.col) / cols
            // Flip Y: row 0 in image = top row, but SpriteKit UV origin = bottom-left
            let uvY = CGFloat(Int(rows) - coord.row - 1) / rows
            let rect = CGRect(x: uvX, y: uvY, width: tileW, height: tileH)
            
            let subTexture = SKTexture(rect: rect, in: texture)
            subTexture.filteringMode = .nearest
            return SKTileDefinition(texture: subTexture, size: tileSize)
        }
    }

    private func createTileGroup(definitions: [SKTileDefinition]) -> SKTileGroup {
        let rule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: definitions)
        return SKTileGroup(rules: [rule])
    }
}
