//
//  EnemyAISystem.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 17/3/26.
//

import Foundation
import simd

public final class EnemyAISystem: System {
    public var dependencies: [System.Type] { [KnockbackSystem.self] }

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
                world.getComponent(type: EnemyStateComponent.self, for: enemy)?.mode = .chase
            } else if distToPlayer > state.loseRadius {
                world.getComponent(type: EnemyStateComponent.self, for: enemy)?.mode = .wander
            }

            // compute velocity every frame based on current mode.
            guard let currentState = world.getComponent(type: EnemyStateComponent.self, for: enemy)
            else { continue }

            if currentState.mode == .chase {
                currentState.chaseStrategy.update(entity: enemy, transform: transform, playerPos: playerPos, world: world)
            } else {
                currentState.wanderStrategy.update(entity: enemy, transform: transform, playerPos: playerPos, world: world)
            }
        }
    }
}
