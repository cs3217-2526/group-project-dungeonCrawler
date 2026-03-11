//
//  System.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

public protocol System: AnyObject {

    /// Lower values run first. Use steps of 10 (10, 20, 30…) to leave insertion room without renumbering everything.
    var priority: Int { get }

    /// Called once per game-loop tick.
    func update(deltaTime: Double, world: World)
}
