//
//  EffectsFactory.swift
//  dungeonCrawler
//
//  Created by Letian on 4/4/26.
//

import Foundation

enum WeaponEffectFactory {
    static func makeEffects(from definition: WeaponDefinition) -> [any WeaponEffect] {
        var effects: [any WeaponEffect] = []

        if definition.hasTag("usesMana") {
            guard let manaCost = definition.float("manaCost") else {
                fatalError("Missing manaCost config for weapon '\(definition.id)'")
            }
            effects.append(ConsumeManaEffect(amount: manaCost))
        }

        if definition.hasTag("projectile") {
            guard
                let speed = definition.float("projectileSpeed"),
                let effectiveRange = definition.float("effectiveRange"),
                let damage = definition.float("damage"),
                let spriteName = definition.string("projectileSpriteName"),
                let collisionSize = definition.vector2("collisionSize")
            else {
                fatalError("Invalid projectile config for weapon '\(definition.id)'")
            }

            effects.append(
                SpawnProjectileEffect(
                    speed: speed,
                    effectiveRange: effectiveRange,
                    damage: damage,
                    spriteName: spriteName,
                    collisionSize: collisionSize
                )
            )
        }

        if definition.hasTag("melee") {
            guard
                let damage = definition.float("damage"),
                let range = definition.float("range"),
                let halfAngleDegrees = definition.float("halfAngleDegrees"),
                let maxTargets = definition.int("maxTargets"),
                let swingDuration = definition.float("swingDuration"),
                let swingAngleDegrees = definition.float("swingAngleDegrees")
            else {
                fatalError("Invalid melee config for weapon '\(definition.id)'")
            }

            effects.append(
                MeleeDamageEffect(
                    damage: damage,
                    range: range,
                    halfAngleDegrees: halfAngleDegrees,
                    maxTargets: maxTargets,
                    swingDuration: swingDuration,
                    swingAngleDegrees: swingAngleDegrees
                )
            )
        }

        return effects
    }
}
