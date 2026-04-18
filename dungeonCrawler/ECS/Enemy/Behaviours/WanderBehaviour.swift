//
//  WanderBehaviour.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation
import simd

/// Moves the enemy to random points within wanderRadius while ensuring within room bounds
/// Wander target state is stored in WanderTargetComponent on the entity, and added lazily
/// on first update and removed when this behaviour deactivates.
public struct WanderBehaviour: EnemyBehaviour {

    public var wanderRadius: Float
    public var wanderSpeed: Float
    /// Minimum inset from room walls. Prevents the wander target from landing
    /// inside or beyond a wall tile, which would pin the enemy against the boundary.
    public var wallMargin: Float

    public init(wanderRadius: Float = 100, wanderSpeed: Float = 40, wallMargin: Float = 40) {
        self.wanderRadius = wanderRadius
        self.wanderSpeed = wanderSpeed
        self.wallMargin = wallMargin
    }

    public func update(entity: Entity, context: BehaviourContext) {
        let arrivalThreshold: Float = 8

        if context.world.getComponent(type: WanderTargetComponent.self, for: entity) == nil {
            context.world.addComponent(component: WanderTargetComponent(), to: entity)
        }

        let currentTarget = context.world.getComponent(type: WanderTargetComponent.self, for: entity)?.target

        if currentTarget == nil ||
            simd_length(context.transform.position - currentTarget!) < arrivalThreshold {
            let newTarget = getCandidateTarget(from: context.transform.position,
                                               bounds: context.roomBounds) ?? currentTarget
            context.world.getComponent(type: WanderTargetComponent.self, for: entity)?.target = newTarget
        }

        guard let target = context.world.getComponent(type: WanderTargetComponent.self,
                                                       for: entity)?.target else { return }

        let wanderDelta = target - context.transform.position
        guard simd_length_squared(wanderDelta) > 1e-6 else { return }

        context.world.getComponent(type: VelocityComponent.self, for: entity)?.linear = normalize(wanderDelta) * self.wanderSpeed * context.slowMultiplier
    }

    /// Discard WanderTargetComponent when no longer in use
    public func onDeactivate(entity: Entity, context: BehaviourContext) {
        context.world.removeComponent(type: WanderTargetComponent.self, from: entity)
    }

    /// Try to obtain a valid target within the room's safe area.
    /// Tries up to 5 random candidates within `wanderRadius`; skips any that fall
    /// outside `bounds` (inset by `wallMargin`). Falls back to a random point
    /// anywhere inside the safe area if all directed candidates are rejected.
    private func getCandidateTarget(from origin: SIMD2<Float>, bounds: RoomBounds?) -> SIMD2<Float>? {
        let minRadius = wanderRadius * 0.25
        let safeArea = bounds?.inset(by: wallMargin)

        for _ in 0..<5 {
            let angle = Float.random(in: 0..<(2 * .pi))
            let radius = Float.random(in: minRadius...wanderRadius)
            let candidate = origin + SIMD2(cos(angle) * radius, sin(angle) * radius)
            guard simd_length_squared(candidate - origin) > 1e-6 else { continue }
            if let safe = safeArea, !safe.contains(candidate) { continue }
            return candidate
        }

        // All directed candidates were outside the room — fall back to any point in the safe area
        if let safe = safeArea, safe.size.x > 0, safe.size.y > 0 {
            let x = Float.random(in: safe.minX...safe.maxX)
            let y = Float.random(in: safe.minY...safe.maxY)
            return SIMD2<Float>(x, y)
        }

        return nil
    }
}
