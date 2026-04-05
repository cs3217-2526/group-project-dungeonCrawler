import Foundation

// MARK: - Protocol

/// Renders the visual background (floors, walls, corridors) for a dungeon level.
///
/// Implementations receive geometric descriptions of rooms and corridors expressed in
/// framework types only — no SpriteKit dependency here. The concrete adapter
/// (`SpriteKitTileMapAdapter`) receives its scene layer at `init` time.
///
/// **Lifecycle:**
/// `LevelOrchestrator` calls `renderRoom` / `renderCorridor` during `loadLevel`,
/// and `tearDownAll` during level reset.
public protocol TileMapRenderer: AnyObject {

    /// Paint tile background for a single room.
    func renderRoom(
        roomID: UUID,
        bounds: RoomBounds,
        doorways: [Doorway],
        theme: TileTheme,
        using generator: inout SeededGenerator
    )

    /// Paint tile background for a corridor between two rooms.
    func renderCorridor(
        roomID: UUID,
        bounds: RoomBounds,
        axis: CorridorAxis,
        theme: TileTheme,
        using generator: inout SeededGenerator
    )

    /// Paint barrier tiles at a single locked-room doorway.
    ///
    /// - Parameters:
    ///   - roomID: The locked room that owns this barrier. Used to group barriers for teardown.
    ///   - bounds: World-space bounds of the barrier strip.
    ///   - side:   Which side of the corridor this barrier sits on.
    func renderBarrier(
        roomID: UUID,
        bounds: RoomBounds,
        side:   BarrierSide,
        theme:  TileTheme,
        using generator: inout SeededGenerator
    )

    /// Remove all barrier tile maps associated with `roomID` (called when a room is cleared).
    func tearDownBarriers(roomID: UUID)

    /// Remove all tile map nodes from the scene (called on level teardown).
    func tearDownAll()
}


