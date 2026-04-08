import Foundation

/// Holds the global state of the current level.
/// Attached to a single "Global Entity" in the world.
public class LevelStateComponent: Component {
    /// The graph structure of the current level.
    public var graph: DungeonGraph?
    
    /// The ID of the currently active room node.
    public var activeNodeID: UUID?
    
    /// The ID and entry position of a room that is currently being entered but not yet locked.
    public var pendingLockdown: (roomID: UUID, entryPos: SIMD2<Float>)?
    
    public init(graph: DungeonGraph? = nil, activeNodeID: UUID? = nil) {
        self.graph = graph
        self.activeNodeID = activeNodeID
        self.pendingLockdown = nil
    }
}
