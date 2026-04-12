//
//  WanderBehaviour.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation
import simd

/// Moves the enemy to random points within wanderRadius.
/// Wander target state is stored in WanderTargetComponent on the entity,
/// added lazily on first update and removed when this behaviour deactivates.
public struct WanderBehaviour: EnemyBehaviour {

    public var wanderRadius: Float
    public var wanderSpeed: Float

    public init(wanderRadius: Float = 100, wanderSpeed: Float = 40) {
        self.wanderRadius = wanderRadius
        self.wanderSpeed = wanderSpeed
    }

    public func update(entity: Entity, context: BehaviourContext) {
        let arrivalThreshold: Float = 8

        if context.world.getComponent(type: WanderTargetComponent.self, for: entity) == nil {
            context.world.addComponent(component: WanderTargetComponent(), to: entity)
        }

        let currentTarget = context.world.getComponent(type: WanderTargetComponent.self, for: entity)?.target

        if currentTarget == nil ||
            simd_length(context.transform.position - currentTarget!) < arrivalThreshold {
            let newTarget = getCandidateTarget(from: context.transform.position) ?? currentTarget
            context.world.getComponent(type: WanderTargetComponent.self, for: entity)?.target = newTarget
        }

        guard let target = context.world.getComponent(type: WanderTargetComponent.self,
                                                       for: entity)?.target else { return }

        let wanderDelta = target - context.transform.position
        guard simd_length_squared(wanderDelta) > 1e-6 else { return }

        context.world.getComponent(type: VelocityComponent.self, for: entity)?.linear = normalize(wanderDelta) * self.wanderSpeed
    }

    /// Discard WanderTargetComponent when no longer in use
    public func onDeactivate(entity: Entity, context: BehaviourContext) {
        context.world.removeComponent(type: WanderTargetComponent.self, from: entity)
    }

    /// Try to obtain a valid target that is significantly far away from where entity is already at
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
