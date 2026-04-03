//
//  InvincibilityComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 29/3/26.
//

import Foundation

/// Attached to an entity immediately after it takes damage.
/// Prevents further damage hits until the timer expires.
/// Removed by InvincibilitySystem once remainingTime reaches zero.
public struct InvincibilityComponent: Component {
    public var remainingTime: Float
 
    public init(remainingTime: Float = 0.5) {
        self.remainingTime = remainingTime
    }
}
