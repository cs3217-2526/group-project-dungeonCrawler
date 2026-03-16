//
//  HealthComponent.swift
//  dungeonCrawler
//
//  Created by Ger Teck on 16/3/26.
//

import Foundation

public struct HealthComponent: StatProvidable {
    public var value: StatValue

    /// Use when Starting Health is Max Health
    public init(base: Float) {
        self.value = StatValue(base: base, max: base)
    }

    /// Use when Max Health is different from Starting Health
    public init(base: Float, max: Float) {
        self.value = StatValue(base: base, max: max)
    }
}
