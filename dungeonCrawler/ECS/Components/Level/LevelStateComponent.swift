import Foundation

/// Holds the global state of the current level.
/// Attached to a single "Global Entity" in the world.
public struct LevelStateComponent: Component {
    /// The graph structure of the current level.
    public var graph: DungeonGraph?
    
    /// The ID of the currently active room node.
    public var activeNodeID: UUID?
    
    public init(graph: DungeonGraph? = nil, activeNodeID: UUID? = nil) {
        self.graph = graph
        self.activeNodeID = activeNodeID
    }
}
