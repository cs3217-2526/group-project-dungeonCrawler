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
    let range: Float
    let halfAngleDegrees: Float
    let maxTargets: Int
    let swingDuration: Float
    let swingAngleDegrees: Float

    func apply(context: FireContext) -> FireEffectResult {

        let origin = context.firePosition
        let facing = context.world.getComponent(type: FacingComponent.self, for: context.weapon)?.facing ?? .right
        let directionSign: Float = facing == .right ? 1 : -1
        let amplitude = swingAngleDegrees * .pi / 180
        let baseRotation = context.world.getComponent(type: TransformComponent.self, for: context.weapon)?.rotation ?? 0
        
        context.world.modifyComponent(
            type: WeaponSwingComponent.self,
            for: context.weapon,
            component: WeaponSwingComponent(
                elapsed: 0,
                duration: swingDuration,
                baseRotation: baseRotation,
                amplitude: amplitude,
                directionSign: directionSign)) { swing in
            swing.elapsed = 0
            swing.duration = swingDuration
            swing.baseRotation = baseRotation
            swing.amplitude = amplitude
            swing.directionSign = directionSign
        }

        var forward = context.fireDirection
        if simd_length_squared(forward) < 0.0001 {
            forward = facing == .right ? SIMD2<Float>(1, 0) : SIMD2<Float>(-1, 0)
        } else {
            forward = simd_normalize(forward)
        }

        let maxDistanceSquared = range * range
        let cosThreshold = cos(halfAngleDegrees * .pi / 180)

        var candidates: [(entity: Entity, distanceSquared: Float)] = []
        for enemy in context.world.entities(with: EnemyTagComponent.self) {
            guard let enemyTransform = context.world.getComponent(type: TransformComponent.self, for: enemy),
                  context.world.getComponent(type: HealthComponent.self, for: enemy) != nil else { continue }

            let toEnemy = enemyTransform.position - origin
            let distanceSquared = simd_length_squared(toEnemy)
            // circle
            guard distanceSquared > 0, distanceSquared <= maxDistanceSquared else { continue }

            let directionToEnemy = simd_normalize(toEnemy)
            // fan shaped
            guard simd_dot(forward, directionToEnemy) >= cosThreshold else { continue }

            candidates.append((entity: enemy, distanceSquared: distanceSquared))
        }

        if !candidates.isEmpty {
            candidates.sort { $0.distanceSquared < $1.distanceSquared }

            var hitCount = 0
            for candidate in candidates {
                context.world.modifyComponentIfExist(type: HealthComponent.self, for: candidate.entity) { health in
                    health.value.current -= damage
                    health.value.clampToMin()
                }
                hitCount += 1
                if hitCount >= maxTargets { break }
            }
        }

        // Successful even on a miss so cooldown and swing animation still apply.
        return .success
    }
}
