//
//  EnemyAISystem.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 17/3/26.
//

import Foundation
import simd

public final class EnemyAISystem: System {
    public let priority: Int = 15

    public init() {}

    public func update(deltaTime: Double, world: World) {
        let player = world.entities(with: PlayerTagComponent.self, and: TransformComponent.self)

        guard let (_, _, playerTransform) = player.first else { return }
        let playerPos = playerTransform.position

        let enemies = world.entities(with: EnemyStateComponent.self, and: TransformComponent.self)

        for (enemy, state, transform) in enemies {
            guard world.getComponent(type: KnockbackComponent.self, for: enemy) == nil else { continue }
            guard world.getComponent(type: VelocityComponent.self, for: enemy) != nil else { continue }
            guard world.getComponent(type: EnemyStateComponent.self, for: enemy) != nil else { continue }

            let distToPlayer = simd_length(playerPos - transform.position)

            // transition mode based on distance thresholds only
            // between detectionRadius and loseRadius, mode is unchanged
            if distToPlayer <= state.detectionRadius {
                world.modifyComponent(type: EnemyStateComponent.self, for: enemy) { $0.mode = .chase }
            } else if distToPlayer > state.loseRadius {
                world.modifyComponent(type: EnemyStateComponent.self, for: enemy) { $0.mode = .wander }
            }

            // compute velocity every frame based on current mode.
            guard let currentState = world.getComponent(type: EnemyStateComponent.self, for: enemy)
            else { continue }

            if currentState.mode == .chase {
                let delta = playerPos - transform.position
                guard simd_length_squared(delta) > 1e-6 else { continue }

                world.modifyComponent(type: VelocityComponent.self, for: enemy) { vel in
                    vel.linear = normalize(delta) * currentState.chaseSpeed
                }
            } else {
                // if there are no targets or considered arrived at wander target,
                // wander to a new point
                world.modifyComponent(type: EnemyStateComponent.self, for: enemy) { s in
                    let arrivalThreshold: Float = 8
                    if s.wanderTarget == nil ||
                       simd_length(transform.position - s.wanderTarget!) < arrivalThreshold {
                        let angle = Float.random(in: 0..<(2 * .pi))
                        let radius = Float.random(in: 0...s.wanderRadius)
                        s.wanderTarget = transform.position +
                            SIMD2(cos(angle) * radius, sin(angle) * radius)
                    }
                }

                guard let target = world.getComponent(type: EnemyStateComponent.self,
                                                      for: enemy)?.wanderTarget
                else { continue }

                let wanderDelta = target - transform.position
                guard simd_length_squared(wanderDelta) > 1e-6 else { continue }
                
                world.modifyComponent(type: VelocityComponent.self, for: enemy) { vel in
                    vel.linear = normalize(wanderDelta) * currentState.wanderSpeed
                }
            }
        }
    }
}
