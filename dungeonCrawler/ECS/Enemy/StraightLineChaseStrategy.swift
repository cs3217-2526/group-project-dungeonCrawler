//
//  ChaseStrategy.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 27/3/26.
//

import Foundation
import simd

/// Basic Chase Strategy with Enemies moving towards Player in a straight line with Chase Speed
public final class StraightLineChaseStrategy: EnemyAIStrategy {

    public func update(entity: Entity, transform: TransformComponent, playerPos: SIMD2<Float>, world: World) {
        let delta = playerPos - transform.position
        guard simd_length_squared(delta) > 1e-6 else { return }

        guard let currentState = world.getComponent(type: EnemyStateComponent.self, for: entity) else { return }
        world.modifyComponent(type: VelocityComponent.self, for: entity) {
            vel in
                vel.linear = normalize(delta) * currentState.chaseSpeed
        }
    }
}
