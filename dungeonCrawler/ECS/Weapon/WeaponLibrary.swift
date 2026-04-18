//
//  WeaponLibrary.swift
//  dungeonCrawler
//
//  Created by Letian on 9/4/26.
//

import Foundation
import simd

enum WeaponType: CaseIterable {
    case handgun
    case sword
    case sniper
    case bazooka
    case spellBook

    var baseDefinition: WeaponBase {
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
                    SpawnProjectileEffect(
                        speed: 300,
                        effectiveRange: 400,
                        damage: 15,
                        spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6),
                        hitEffects: []
                    ),
                    ConsumeAmmoEffect(),
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
                    SpawnProjectileEffect(
                        speed: 400, effectiveRange: 800,
                        damage: 50, spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6),
                        hitEffects: []
                    ),
                    ConsumeAmmoEffect(),
                ],
                anchorPoint: nil,
                initRotation: nil,
                ammoConfig: AmmoConfig(magazineSize: 1, reloadTime: 2.0)
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
                    ConsumeAmmoEffect(),
                    SpawnRocketEffect(
                        speed: 300,
                        damage: 80,
                        spriteName: "rocket",
                        collisionSize: SIMD2<Float>(10, 10),
                        gravity: 200,
                        launchAngle: 0),
                    ConsumeAmmoEffect(),
                ],
                anchorPoint: nil,
                initRotation: nil,
                ammoConfig: AmmoConfig(magazineSize: 1, reloadTime: 3.0)
                // ammoConfig intentionally nil — mana-gated only
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
                    SpawnProjectileEffect(
                        speed: 250,
                        effectiveRange: 500,
                        damage: 30,
                        spriteName: "magicOrb",
                        collisionSize: SIMD2<Float>(8, 8),
                        hitEffects: [SlowEffect(multiplier: 0.4, duration: 2.0)]
                    ),
                ],
                anchorPoint: nil,
                initRotation: nil
                // ammoConfig intentionally nil — mana-gated only
            )
        
        }
    }
}
