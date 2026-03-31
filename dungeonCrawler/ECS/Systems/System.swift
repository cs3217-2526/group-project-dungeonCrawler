//
//  System.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

public protocol System: AnyObject {

    /// Systems that must finish before this system runs each update.
    /// SystemManager builds a dependency DAG from these declarations and
    /// runs a topological sort to determine execution order automatically.
    /// Declare only direct prerequisites — transitive ordering is inferred.
    var dependencies: [System.Type] { get }

    /// Called once per game-loop tick.
    func update(deltaTime: Double, world: World)
}

public extension System {
    /// Default: no prerequisites.
    /// Systems that run unconditionally first need not override this.
    var dependencies: [System.Type] { [] }
}
