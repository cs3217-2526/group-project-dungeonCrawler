//
//  StatType.swift
//  dungeonCrawler
//

import Foundation

/// A type-safe, string-backed key identifying a single stat.
/// Extend this type to add new stats without modifying any existing file.
///
/// E.g.: in a new file
/// ```swift
/// extension StatType {
///     static let experience = StatType(rawValue: "xp")
///     static let level = StatType(rawValue: "level")
/// }
/// ```
public struct StatType: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

// Built-in stat types
public extension StatType {
    static let health    = StatType(rawValue: "health")
    static let moveSpeed = StatType(rawValue: "moveSpeed")
    static let attack    = StatType(rawValue: "attack")
    static let defence   = StatType(rawValue: "defence")
}

/// The value held at a single stat slot.
public struct StatValue {
    // base is the unmodified value
    public var base: Float
    // current is the runtime value (takes damage, buffs, etc.)
    public var current: Float

    public var min: Float
    public var max: Float?          // nil = uncapped

    /// Convenience init: current starts equal to base.
    public init(base: Float, min: Float = 0, max: Float? = nil) {
        self.base    = base
        self.current = base
        self.min     = min
        self.max     = max
    }
}
