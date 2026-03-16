//
//  StatsComponent.swift
//  dungeonCrawler
//

import Foundation

/// Holds an arbitrary set of named stats for an entity.
/// Systems read and write individual stats by StatType key.
public final class StatsComponent: Component {
    public var stats: [StatType: StatValue]

    public init(stats: [StatType: StatValue] = [:]) {
        self.stats = stats
    }

    /// Convenience accessor.
    public func value(for type: StatType) -> StatValue? {
        stats[type]
    }
}
