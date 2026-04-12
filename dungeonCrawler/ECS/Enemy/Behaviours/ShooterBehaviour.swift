//
//  ShooterBehaviour.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation
import simd

/// A basic behaviour for shooter-type enemies.
/// The entity picks a target spot within an annular zone around the chase target (context.playerPos),
/// walks to it, briefly stops, then picks another spot — forming a zigzag arc.
/// Target positions are stored as polar coords relative to the chase target in ShooterBasicComponent.
///
/// - Note: The arc constraint (arcRange) is only applied when picking a new target hop.
///   If the chase target moves significantly mid-hop, the current target's angle relative
///   to the new chase target position may fall outside the original arc range.
///   This is accepted as-is; rapid target movement will produce slightly erratic arcs.
public struct ShooterBehaviour: EnemyBehaviour {

    public var innerRadius: Float
    public var outerRadius: Float
    public var moveSpeed: Float
    public var arcRange: Float

    public init(
        innerRadius: Float = 100,
        outerRadius: Float = 200,
        moveSpeed: Float = 60,
        arcRange: Float = .pi / 3
    ) {
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.moveSpeed = moveSpeed
        self.arcRange = arcRange
    }

    public func update(entity: Entity, context: BehaviourContext) {
        if context.world.getComponent(type: ShooterBasicComponent.self, for: entity) == nil {
            context.world.addComponent(component: ShooterBasicComponent(), to: entity)
        }

        let comp = context.world.getComponent(type: ShooterBasicComponent.self, for: entity)!
        let arrivalThreshold: Float = 10

        let targetWorldPos: SIMD2<Float>? = {
            guard let angle = comp.targetAngle, let radius = comp.targetRadius else { return nil }
            return context.playerPos + SIMD2(cos(angle) * radius, sin(angle) * radius)
        }()

        let arrived = targetWorldPos.map {
            simd_length(context.transform.position - $0) < arrivalThreshold
        } ?? true

        if arrived {
            context.world.getComponent(type: VelocityComponent.self, for: entity)?.linear = SIMD2<Float>.zero

            if let (angle, radius) = pickTarget(from: context.transform.position,
                                                playerPos: context.playerPos) {
                if let comp = context.world.getComponent(type: ShooterBasicComponent.self, for: entity) {
                    comp.targetAngle = angle
                    comp.targetRadius = radius
                }
            }
            return
        }

        guard let target = targetWorldPos else { return }
        let moveDir = target - context.transform.position
        guard simd_length_squared(moveDir) > 1e-6 else { return }

        context.world.getComponent(type: VelocityComponent.self, for: entity)?.linear = normalize(moveDir) * self.moveSpeed
    }

    /// Remove ShooterBasicComponent when no longer in use.
    public func onDeactivate(entity: Entity, context: BehaviourContext) {
        context.world.removeComponent(type: ShooterBasicComponent.self, from: entity)
    }

    // Ensure that the candidate pos is significantly further away from current pos
    private func pickTarget(from currentPos: SIMD2<Float>,
                            playerPos: SIMD2<Float>) -> (Float, Float)? {
        let currentDelta = currentPos - playerPos
        let currentAngle = atan2(currentDelta.y, currentDelta.x)

        for _ in 0..<8 {
            let angle = currentAngle + Float.random(in: -arcRange...arcRange)
            let radius = Float.random(in: innerRadius...outerRadius)
            let candidate = playerPos + SIMD2(cos(angle) * radius, sin(angle) * radius)
            if simd_length_squared(candidate - currentPos) > 1e-6 {
                return (angle, radius)
            }
        }
        return nil
    }
}
