//
//  WanderStrategy.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 27/3/26.
//

import Foundation
import simd

/// A strategy that moves an enemy to random points within wanderRadius.
/// Wander target state is stored in WanderTargetComponent on the entity,
/// added lazily on first update — stationary enemies will never receive it.
public struct WanderStrategy: EnemyAIStrategy {

    public var wanderRadius: Float
    public var wanderSpeed: Float

    public init(wanderRadius: Float = 100, wanderSpeed: Float = 40) {
        self.wanderRadius = wanderRadius
        self.wanderSpeed = wanderSpeed
    }

    /// entity refers to Enemy here and the transform is the enemy's transform
    public func update(entity: Entity, transform: TransformComponent, playerPos: SIMD2<Float>, world: World) {
        let arrivalThreshold: Float = 8

        // Lazily attach WanderTargetComponent on first use
        if world.getComponent(type: WanderTargetComponent.self, for: entity) == nil {
            world.addComponent(component: WanderTargetComponent(), to: entity)
        }

        let currentTarget = world.getComponent(type: WanderTargetComponent.self, for: entity)?.target

        if currentTarget == nil ||
            simd_length(transform.position - currentTarget!) < arrivalThreshold {
            let newTarget = getCandidateTarget(from: transform.position) ?? currentTarget
            world.getComponent(type: WanderTargetComponent.self, for: entity)?.target = newTarget
        }

        guard let target = world.getComponent(type: WanderTargetComponent.self, for: entity)?.target else { return }

        let wanderDelta = target - transform.position
        guard simd_length_squared(wanderDelta) > 1e-6 else { return }

        world.getComponent(type: VelocityComponent.self, for: entity)?.linear = normalize(wanderDelta) * wanderSpeed
    }

    /// helper to get a wander target that is sufficiently far from current position
    /// will return nil if fail to get such a candidate in 5 tries
    private func getCandidateTarget(from origin: SIMD2<Float>) -> SIMD2<Float>? {
        let minRadius = wanderRadius * 0.25
        for _ in 0..<5 {
            let angle = Float.random(in: 0..<(2 * .pi))
            let radius = Float.random(in: minRadius...wanderRadius)
            let candidate = origin + SIMD2(cos(angle) * radius, sin(angle) * radius)
            if simd_length_squared(candidate - origin) > 1e-6 {
                return candidate
            }
        }
        return nil
    }
}
