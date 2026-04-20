//
//  PoisonEffect.swift
//  dungeonCrawler
//
//  Created by Letian on 20/4/26.
//

import Foundation

public struct PoisonEffect: ProjectileHitEffect {
    public let multiplier: Float   // fraction of normal speed, e.g. 0.4 = 40%
    public let duration: Float     // seconds

    public init(multiplier: Float = 0.4, duration: Float = 2.0) {
        self.multiplier = multiplier
        self.duration = duration
    }

    public func apply(context: HitContext) {
        guard let target = context.target else { return }
        if let existing = context.world.getComponent(type: SlowComponent.self, for: target) {
            existing.remaining = max(existing.remaining, duration)
            existing.multiplier = min(existing.multiplier, multiplier)
        } else {
            context.world.addComponent(
                component: SlowComponent(multiplier: multiplier, remaining: duration),
                to: target
            )
        }
    }
}
