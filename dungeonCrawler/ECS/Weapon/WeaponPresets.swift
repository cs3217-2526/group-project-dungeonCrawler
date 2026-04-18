//
//  WeaponPresets.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/4/26.
//

import Foundation
import simd

public extension WeaponBase {

    /// Basic ranged weapon used by the Ranger enemy.
    /// No ammo config — enemies have unlimited supply.
    static let enemyRangedDefault = WeaponBase(
        textureName: "EnemyBullet",
        offset: .zero,
        scale: 1.0,
        lastFiredAt: nil,
        cooldown: 0.5,
        attackSpeed: 150,
        effects: [
            SpawnProjectileEffect(
                speed: 180,
                effectiveRange: 300,
                damage: 8,
                spriteName: "normalHandgunBullet",
                collisionSize: SIMD2<Float>(6, 6),
                hitEffects: []
            )
        ],
        anchorPoint: SIMD2<Float>(0.5, 0.5),
        initRotation: 0
    )

    /// Attack weapon used by the Tower enemy.
    static let towerAttack = WeaponBase(
        textureName: "EnemyBullet",
        offset: .zero,
        scale: 1.0,
        lastFiredAt: nil,
        cooldown: 0.2,
        attackSpeed: 200,
        effects: [
            SpawnProjectileEffect(
                speed: 250,
                effectiveRange: 300,
                damage: 8,
                spriteName: "normalHandgunBullet",
                collisionSize: SIMD2<Float>(6, 6),
                hitEffects: []
            )
        ],
        anchorPoint: SIMD2<Float>(0.5, 0.5),
        initRotation: 0
    )
}
