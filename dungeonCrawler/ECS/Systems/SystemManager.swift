//
//  SystemManager.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

/// Owns and orchestrates every system in the game.
/// Execution order is determined by a topological sort over each system's declared
/// dependency graph — no manual priority numbers required.
public final class SystemManager {

    private var _systems: [ObjectIdentifier: any System] = [:]
    private var _sortedSystems: [any System] = []
    private var _isDirty = false

    // MARK: - Registration

    public func register(_ system: any System) {
        /// keyed by type identity so that no duplicate systems are allowed
        _systems[ObjectIdentifier(type(of: system))] = system
        _isDirty = true
    }

    public func unregister<T: System>(_ type: T.Type) {
        _systems[ObjectIdentifier(type)] = nil
        _isDirty = true
    }

    // MARK: - Game Loop

    public func update(deltaTime: Double, world: World) {
        if _isDirty {
            _sortedSystems = topologicalSort()
            _isDirty = false
        }
        for system in _sortedSystems {
            system.update(deltaTime: deltaTime, world: world)
        }
    }

    // MARK: - Topological Sort (Kahn's algorithm)

    private func topologicalSort() -> [any System] {
        var graph = Graph<ObjectIdentifier, any System, Void>()

        for (id, system) in _systems {
            graph.setNode(id, data: system)
        }

        for (id, system) in _systems {
            for depType in system.dependencies {
                let depID = ObjectIdentifier(depType)
                guard graph.hasNode(depID) else { continue }
                graph.addEdge(from: depID, to: id, data: ())
            }
        }

        var inDegree: [ObjectIdentifier: Int] = Dictionary(
            uniqueKeysWithValues: graph.allNodeIDs.map { ($0, 0) }
        )
        for edge in graph.allEdges {
            inDegree[edge.to, default: 0] += 1
        }

        var queue = inDegree.filter { $0.value == 0 }.map { $0.key }
        var sorted: [any System] = []

        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let system = graph.node(current) {
                sorted.append(system)
            }
            for neighborID in graph.neighbors(of: current) {
                inDegree[neighborID]! -= 1
                if inDegree[neighborID]! == 0 {
                    queue.append(neighborID)
                }
            }
        }

        assert(sorted.count == graph.nodeCount,
               "Cycle detected in system dependency graph — check for circular dependencies.")
        return sorted
    }
}
