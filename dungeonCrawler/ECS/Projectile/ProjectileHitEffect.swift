//
//  ProjectileHitEffect.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation
import simd

public protocol ProjectileHitEffect {
    func apply(context: ZoneContext)
}

public struct SpawnZoneEffect: ProjectileHitEffect {
    public func apply(context: ZoneContext) {
        let zoneBase = context.zoneBase
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
