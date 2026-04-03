//
//  ShooterZigZagStrategy.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 1/4/26.
//

import Foundation
import simd

/// A chase strategy for shooter-type enemies.
///
/// The enemy picks a target spot within an annular zone (ring) around the player,
/// walks to it, briefly stops, and then picks another spot.
///
/// The next target is constrained to within `±arcRange` of the enemy's
/// current angle relative to the player, so hops are short and form a zigzag arc.
///
/// Target positions are stored as polar coords relative to the player so they track
/// the player as they move.
///
/// Note that the shooter is allowed to walk and shoot based on this implementation
public struct ShooterBasicStrategy: EnemyAIStrategy {

    // Closest the enemy will get to the player.
    public var innerRadius: Float

    // Furthest the enemy will stand from the player.
    public var outerRadius: Float

    public var moveSpeed: Float

    // determines the distance enemy move between each points
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

    public func update(entity: Entity, transform: TransformComponent,
                       playerPos: SIMD2<Float>, world: World) {
        if world.getComponent(type: ShooterBasicComponent.self, for: entity) == nil {
            world.addComponent(component: ShooterBasicComponent(), to: entity)
        }

        let comp = world.getComponent(type: ShooterBasicComponent.self, for: entity)!
        let arrivalThreshold: Float = 10

        let targetWorldPos: SIMD2<Float>? = {
            guard let angle = comp.targetAngle, let radius = comp.targetRadius else { return nil }
            return playerPos + SIMD2(cos(angle) * radius, sin(angle) * radius)
        }()

        let arrived = targetWorldPos.map {
            simd_length(transform.position - $0) < arrivalThreshold
        } ?? true

        if arrived {
            world.modifyComponentIfExist(type: VelocityComponent.self, for: entity) { $0.linear = .zero }

            // Pick the next target near the current angle
            if let (angle, radius) = pickTarget(from: transform.position, playerPos: playerPos) {
                world.modifyComponentIfExist(type: ShooterBasicComponent.self, for: entity) {
                    $0.targetAngle = angle
                    $0.targetRadius = radius
                }
            }
            return
        }

        guard let target = targetWorldPos else { return }
        let moveDir = target - transform.position
        guard simd_length_squared(moveDir) > 1e-6 else { return }

        world.modifyComponentIfExist(type: VelocityComponent.self, for: entity) { vel in
            vel.linear = normalize(moveDir) * self.moveSpeed
        }
    }

    /// Returns a (angle, radius) pair for a new target in the annulus within `arcRange`
    /// of the enemy's current angle relative to the player.
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
