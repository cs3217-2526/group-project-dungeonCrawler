//
//  WeaponLibrary.swift
//  dungeonCrawler
//
//  Created by Letian on 9/4/26.
//

import Foundation
import simd

public enum WeaponType: CaseIterable {
    case handgun
    case sword
    case axe
    case sniper
    case bazooka
    case spellBook
    case poisonBottle
    case enemyRangedDefault
    case towerAttack

    public var baseDefinition: WeaponBase {
        switch self {

        // Firearms:
        // ConsumeManaEffect is intentionally absent.
        // ConsumeAmmoEffect gates firing and drives the reload cycle.

        case .handgun:
            WeaponBase(
                textureName: "handgun",
                offset: SIMD2<Float>(8, -18),
                scale: WorldConstants.standardEntityScale,
                lastFiredAt: 0,
                cooldown: TimeInterval(0.2),
                attackSpeed: 1,
                effects: [
                    ConsumeAmmoEffect(),
                    SpawnLinearProjectileEffect(
                        speed: 300,
                        effectiveRange: 400,
                        spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6),
                        hitEffects: [
                            DamageEffect(amount: 15)
                        ]
                    ),
                ],
                anchorPoint: nil,
                initRotation: nil,
                ammoConfig: AmmoConfig(magazineSize: 6, reloadTime: 2.0)
            )

        case .sniper:
            WeaponBase(
                textureName: "Sniper",
                offset: SIMD2<Float>(10, -8),
                scale: WorldConstants.standardEntityScale,
                lastFiredAt: 0,
                cooldown: TimeInterval(0.8),
                attackSpeed: 1,
                effects: [
                    ConsumeAmmoEffect(),
                    SpawnLinearProjectileEffect(
                        speed: 400, effectiveRange: 800,
                        spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6),
                        hitEffects: [
                            DamageEffect(amount: 50)
                        ]
                    ),
                ],
                anchorPoint: nil,
                initRotation: nil,
                ammoConfig: AmmoConfig(magazineSize: 1, reloadTime: 2.0)
            )

        // Melee:
        // No ammo config, no mana cost — just swing cooldown.

        case .sword:
            WeaponBase(
                textureName: "sword",
                offset: SIMD2<Float>(20, -15),
                scale: 0.3,
                lastFiredAt: 0,
                cooldown: 0.5,
                attackSpeed: 1,
                effects: [
                    MeleeDamageEffect(
                        damage: 50, range: 100,
                        halfAngleDegrees: 90,
                        maxTargets: 1,
                        swingDuration: 0.3,
                        swingAngleDegrees: 40
                    )
                ],
                anchorPoint: SIMD2<Float>(0.2, 0.5),
                initRotation: .pi / 9
            )

        case .axe:
            WeaponBase(
                textureName: "axe",
                offset: SIMD2<Float>(20, -15),
                scale: 0.3,
                lastFiredAt: 0,
                cooldown: 0.6,
                attackSpeed: 1,
                effects: [
                    ChargeEffect(required: 1.2),
                    MeleeDamageEffect(
                        damage: 120, range: 110,
                        halfAngleDegrees: 90,
                        maxTargets: 3,
                        swingDuration: 0.35,
                        swingAngleDegrees: 60
                    )
                ],
                anchorPoint: SIMD2<Float>(0.2, 0.5),
                initRotation: .pi / 9
            )

        // Magical:
        // ConsumeManaEffect gates firing — no ammo component created.

        case .spellBook:
            WeaponBase(
                textureName: "spellbook",
                offset: SIMD2<Float>(8, -18),
                scale: 0.55,
                lastFiredAt: 0,
                cooldown: TimeInterval(0.5),
                attackSpeed: 1,
                effects: [
                    ConsumeManaEffect(amount: 15),
                    SpawnLinearProjectileEffect(
                        speed: 250,
                        effectiveRange: 500,
                        spriteName: "magicOrb",
                        collisionSize: SIMD2<Float>(8, 8),
                        hitEffects: [
                            DamageEffect(amount: 30),
                            SlowEffect(multiplier: 0.4, duration: 2.0),
                            TintEffect(duration: 2.0, newTint: TintLibrary.slowTint.tint)
                        ]
                    ),
                ],
                anchorPoint: nil,
                initRotation: nil
                // ammoConfig intentionally nil — mana-gated only
            )
        
        case .bazooka:
            WeaponBase(
                textureName: "bazooka",
                offset: SIMD2<Float>(10, -5),
                scale: 0.4,
                lastFiredAt: 0,
                cooldown: TimeInterval(1),
                attackSpeed: 1,
                effects: [
                    CheckEnoughAmmoEffect(),
                    SpawnParabolaProjectileEffect(
                        speed: 300,
                        spriteName: "rocket",
                        collisionSize: SIMD2<Float>(10, 10),
                        gravity: 200,
                        launchAngle: 0,
                        hitEffects: [
                            DamageEffect(amount: 80),
                            SpawnZoneEffectsLibrary.fireZone.effect
                        ]
                        ),
                    ConsumeAmmoEffect()
                ],
                anchorPoint: nil,
                initRotation: nil,
                ammoConfig: AmmoConfig(magazineSize: 1, reloadTime: 3.0)
                // ammoConfig intentionally nil — mana-gated only
            )
        case .poisonBottle:
            WeaponBase(
                textureName: "poisonBottle",
                offset: SIMD2<Float>(10, -5),
                scale: 0.6,
                lastFiredAt: 0,
                cooldown: TimeInterval(0.5),
                attackSpeed: 1,
                effects: [
                    CheckEnoughManaEffect(amount: 6),
                    SpawnParabolaProjectileEffect(
                        speed: 300,
                        spriteName: "poisonBottle",
                        collisionSize: SIMD2<Float>(10, 10),
                        gravity: 300,
                        launchAngle: 0,
                        hitEffects: [
                            SpawnZoneEffectsLibrary.poisonZone.effect
                        ],
                        scale: 0.6
                        ),
                    ConsumeManaEffect(amount: 6),
                ],
                anchorPoint: nil,
                initRotation: .pi / 9)
        case .enemyRangedDefault:
            WeaponBase(
                textureName: "EnemyBullet",
                offset: .zero,
                scale: 1.0,
                lastFiredAt: nil,
                cooldown: 0.5,
                attackSpeed: 150,
                effects: [
                    SpawnLinearProjectileEffect(
                        speed: 180,
                        effectiveRange: 300,
                        spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6),
                        hitEffects: [
                            DamageEffect(amount: 8)
                        ]
                    )
                ],
                anchorPoint: SIMD2<Float>(0.5, 0.5),
                initRotation: 0
            )
        case .towerAttack:
            WeaponBase(
                textureName: "EnemyBullet",
                offset: .zero,
                scale: 1.0,
                lastFiredAt: nil,
                cooldown: 0.2,
                attackSpeed: 200,
                effects: [
                    SpawnLinearProjectileEffect(
                        speed: 250,
                        effectiveRange: 300,
                        spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6),
                        hitEffects: [
                            DamageEffect(amount: 8)
                        ]
                    )
                ],
                anchorPoint: SIMD2<Float>(0.5, 0.5),
                initRotation: 0
            )
        }
    }
}
