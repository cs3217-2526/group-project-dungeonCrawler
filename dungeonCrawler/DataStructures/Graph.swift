import Foundation

// Generic Directed Graph ADT
// Feel free to optimize it as long as the API same and tests still pass.
// Implementation is currently just an adjacency list with a separate node store.


/// A generic directed graph with typed node data and edge data.
/// NodeID, NodeData, and EdgeData are all generic parameters, defined when the graph is instantiated.
///
/// `NodeID` is the stable identity key (e.g. `UUID`).
/// `NodeData` is for payload stored at each vertex.
/// `EdgeData` is for payload on each directed edge.
public struct Graph<NodeID: Hashable, NodeData, EdgeData> {

    /// Edge: A directed edge from one node to another, carrying typed metadata.
    public struct Edge {
        public let from: NodeID
        public let to:   NodeID
        public let data: EdgeData

        public init(from: NodeID, to: NodeID, data: EdgeData) {
            self.from = from
            self.to   = to
            self.data = data
        }
    }

    private var nodeStore:  [NodeID: NodeData] = [:]
    private var adjacency:  [NodeID: [Edge]]   = [:]

    public init() {}

    /// Inserts or overwrites the node at `id` with `data`.
    public mutating func setNode(_ id: NodeID, data: NodeData) {
        nodeStore[id] = data
        if adjacency[id] == nil { adjacency[id] = [] }
    }

    /// Appends a directed edge from `from` to `to` carrying `data`.
    /// Both endpoints must already exist (added via `setNode`).
    public mutating func addEdge(from: NodeID, to: NodeID, data: EdgeData) {
        adjacency[from, default: []].append(Edge(from: from, to: to, data: data))
    }

    // MARK: - Queries
    /// Returns the data stored at `id`, or `nil` if the node does not exist.
    public func node(_ id: NodeID) -> NodeData? {
        nodeStore[id]
    }

    /// Returns all outgoing edges from `id`.
    public func edges(from id: NodeID) -> [Edge] {
        adjacency[id] ?? []
    }

    /// All node IDs currently in the graph.
    public var allNodeIDs: [NodeID] {
        Array(nodeStore.keys)
    }

    /// All edges across every node (order not guaranteed).
    public var allEdges: [Edge] {
        adjacency.values.flatMap { $0 }
    }

    /// Number of nodes in the graph.
    public var nodeCount: Int {
        nodeStore.count
    }

    /// Returns `true` if a node with `id` exists.
    public func hasNode(_ id: NodeID) -> Bool {
        nodeStore[id] != nil
    }

    /// Returns the IDs of all nodes reachable in one step from `id`.
    public func neighbors(of id: NodeID) -> [NodeID] {
        (adjacency[id] ?? []).map { $0.to }
    }
}
