import Foundation
import CoreGraphics

/// Produces a complete dungeon topology for a level.
public protocol DungeonLayoutStrategy {
    /// Returns `DungeonGraph`: rooms in level and connections.
    func generate(context: GenerationContext) -> DungeonGraph
}

