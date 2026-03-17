//
//  StatValue.swift
//  dungeonCrawler
//
//  Created by Ger Teck on 16/3/26.
//

import Foundation

public struct StatValue {
    public var base: Float
    public var current: Float
    public var max: Float?

    public init(base: Float, max: Float? = nil) {
        self.base = base
        self.current = base
        self.max = max
    }

    public mutating func clampToMax() {
        if let max {
            current = Swift.min(max, current)
        }
    }
}
