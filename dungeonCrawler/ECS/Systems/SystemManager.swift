//
//  SystemManager.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

/// Owns and orchestrates every system in the game. Maintains a sorted array so insertion order never matters.
public final class SystemManager {

    private var _systems: [System] = []

    // MARK: - Registration

    public func register(_ system: System) {
        _systems.append(system)
        _systems.sort { $0.priority < $1.priority }
    }

    public func unregister<T: System>(_ type: T.Type) {
        _systems.removeAll { $0 is T }
    }

    // MARK: - Game Loop

    public func update(deltaTime: Double, world: World) {
        for system in _systems {
            system.update(deltaTime: deltaTime, world: world)
        }
    }
}
