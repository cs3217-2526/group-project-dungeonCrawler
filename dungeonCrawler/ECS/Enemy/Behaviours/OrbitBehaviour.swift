//
//  OrbitBehaviour.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 14/4/26.
//

import Foundation
import simd

/// Moves the enemy in an arc around the player by hopping between
/// polar-coordinate targets in an annular zone (innerRadius … outerRadius).
///
/// Each hop picks a new angle offset (±arcRange) from the current bearing
/// and a random radius, forming a zigzag orbit. Arrival is detected when
/// the enemy reaches within arrivalThreshold of the target world position.
///
/// Target state is stored in ShooterBasicComponent, added lazily on first
/// update and removed on deactivation.
///
/// Pair with ShooterBehaviour (or any other attack behaviour) — this struct
/// only writes to VelocityComponent and manages ShooterBasicComponent.
public struct OrbitBehaviour: EnemyBehaviour {

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

    // MARK: - Lifecycle

    public func onDeactivate(entity: Entity, context: BehaviourContext) {
        context.world.removeComponent(type: ShooterBasicComponent.self, from: entity)
    }

    // MARK: - Update

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

    // MARK: - Private

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
