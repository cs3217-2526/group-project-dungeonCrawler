//
//  ProjectileHitEffect.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation
import simd

public protocol ProjectileHitEffect {
    func apply(context: HitContext)
}

// MARK: - Zone effects

/// Spawns a persistent damage zone at the impact position.
/// Carries its own ZoneBase so the caller never has to inject one through HitContext.
public struct SpawnZoneEffect: ProjectileHitEffect {
    public let zoneBase: ZoneBase

    public init(zoneBase: ZoneBase = HitEffectsLibrary.fireZone.effectDefinition) {
        self.zoneBase = zoneBase
    }

    public func apply(context: HitContext) {
        SpecialEffectZoneEntityFactory(
            textureName: zoneBase.textureName,
            radius: zoneBase.radius,
            damagePerSecond: zoneBase.damagePerSecond,
            duration: zoneBase.duration,
            elapsed: 0,
            position: context.center)
            .make(in: context.world)
    }
}
