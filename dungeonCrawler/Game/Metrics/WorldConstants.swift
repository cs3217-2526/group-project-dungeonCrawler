import Foundation

/// Central source of truth for physical dimensions and scaling.
public enum WorldConstants {
    /// The canonical size of a single grid tile in world units.
    /// This should match the `tileSize` in the tileset JSONs.
    public static let tileSize: Float = 16.0
    
    /// The default thickness of walls (exactly one tile).
    public static let wallThickness: Float = tileSize
    
    /// The standard size for a human-like entity (2.0x tileSize).
    public static let playerSize: Float = 32.0

    /// Standardized entity scale based on a 1024-unit coordinate system and 48-pixel assets.
    /// This ensures actors look the same relative to room sizes (currently ~0.853).
    public static let standardEntityScale: Float = 1024.0 * 0.04 / 48.0

    /// Distance from room boundary to spawn/position player during transitions.
    public static let roomEntryInset: Float = 80.0
}
