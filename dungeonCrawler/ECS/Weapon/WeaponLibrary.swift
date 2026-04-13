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
    
    var baseDefinition: WeaponBase {
        switch self {
        case .handgun:
            WeaponBase(
                textureName: "handgun",
                offset: SIMD2<Float>(8, -18),
                scale: WorldConstants.standardEntityScale,
                lastFiredAt: 0,
                cooldown: TimeInterval(0.2),
                attackSpeed: 1,
                effects: [
                    ConsumeManaEffect(amount: 5),
                    SpawnProjectileEffect(
                        speed: 300,
                        effectiveRange: 400,
                        damage: 15,
                        spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6)
                    ),
                ],
                anchorPoint: nil,
                initRotation: nil,
            )
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
                        swingAngleDegrees: 40)
                ],
                anchorPoint: SIMD2<Float>(0.2, 0.5),
                initRotation: .pi / 9
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
                    ConsumeManaEffect(amount: 20),
                    SpawnProjectileEffect(
                        speed: 400, effectiveRange: 800,
                        damage: 50, spriteName: "normalHandgunBullet",
                        collisionSize: SIMD2<Float>(6, 6)),
                ],
                anchorPoint: nil,
                initRotation: nil,
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
                    ConsumeManaEffect(amount: 3),
                    SpawnRocketEffect(
                        speed: 300,
                        damage: 80,
                        spriteName: "rocket",
                        collisionSize: SIMD2<Float>(10, 10),
                        gravity: 200,
                        launchAngle: 0),
                ],
                anchorPoint: nil,
                initRotation: nil,
            )
        }
    }
}
