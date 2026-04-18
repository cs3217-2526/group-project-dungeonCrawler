//
//  SlowComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 19/4/26.
//

import Foundation

public class SlowComponent: Component {
    /// Fraction of normal speed (0.0–1.0). Lower = slower.
    public var multiplier: Float
    /// Seconds remaining on the slow.
    public var remaining: Float
 
    public init(multiplier: Float, remaining: Float) {
        self.multiplier = multiplier
        self.remaining = remaining
    }
}
 
