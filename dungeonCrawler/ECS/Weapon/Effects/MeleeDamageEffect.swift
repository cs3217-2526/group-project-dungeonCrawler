//
//  MeleeDamageEffect.swift
//  dungeonCrawler
//
//  Created by Letian on 1/4/26.
//

import Foundation
import simd

struct MeleeDamageEffect: WeaponEffect {
    let damage: Float
    let effectiveRange: Float
    let halfAngleDegrees: Float
    let maxTargets: Int

    func apply(context: FireContext) -> FireEffectResult {

        let origin = context.firePosition
        let facing = context.world.getComponent(type: FacingComponent.self, for: context.weapon)?.facing ?? .right

        var forward = context.fireDirection
        if simd_length_squared(forward) < 0.0001 {
            forward = (facing == .right) ? SIMD2<Float>(1, 0) : SIMD2<Float>(-1, 0)
        } else {
            forward = simd_normalize(forward)
        }

        let maxDistSq = effectiveRange * effectiveRange
        let cosThreshold = cos(halfAngleDegrees * .pi / 180)
        // Rotate sword when firing (one attack tick).
        let swing = halfAngleDegrees * .pi / 180
        context.world.modifyComponent(type: TransformComponent.self, for: context.weapon) { t in
            t.rotation += (facing == .right) ? swing : -swing
        }

        var candidates: [(entity: Entity, distSq: Float)] = []

        for enemy in context.world.entities(with: EnemyTagComponent.self) {
            guard let enemyTransform = context.world.getComponent(type: TransformComponent.self, for: enemy),
                  context.world.getComponent(type: HealthComponent.self, for: enemy) != nil else { continue }

            let toEnemy = enemyTransform.position - origin
            let distSq = simd_length_squared(toEnemy)
            guard distSq > 0, distSq <= maxDistSq else { continue }

            let dir = simd_normalize(toEnemy)
            let inFrontCone = simd_dot(forward, dir) >= cosThreshold
            guard inFrontCone else { continue }

            candidates.append((enemy, distSq))
        }

        if candidates.isEmpty {
            return .blocked("no_target_in_range")
        }

        candidates.sort { $0.distSq < $1.distSq }

        var hits = 0
        for (enemy, _) in candidates {
            context.world.modifyComponent(type: HealthComponent.self, for: enemy) { health in
                health.value.current -= damage
                health.value.clampToMin()
            }
            hits += 1
            if hits >= maxTargets { break }
        }

        return .success
    }
}
