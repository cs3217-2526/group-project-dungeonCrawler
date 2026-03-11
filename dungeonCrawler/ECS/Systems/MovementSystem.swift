//
//  MovementSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

public final class MovementSystem: System {

    public let priority: Int = 20

    // MARK: - Configuration

    // TODO: move to StatsComponent when that's added.
    public var defaultMoveSpeed: Float = 200

    // TODO: Remove when CollisionSystem handles wall entities.
    public var worldBounds: (minX: Float, maxX: Float, minY: Float, maxY: Float) = (
        minX: -500, maxX: 500, minY: -500, maxY: 500
    )

    public init() {}

    // MARK: - Update

    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)

        let movable = world.entities(
            with: InputComponent.self,
            and: VelocityComponent.self
        )

        for (entity, input, velocity) in movable {
            guard let transform = world.getComponent(type: TransformComponent.self, for: entity)
            else { continue }

            // Scale the normalised direction by speed to get points-per-second.
            velocity.linear = input.moveDirection * defaultMoveSpeed

            transform.position += velocity.linear * dt

            // Only update rotation when the entity is actually moving to avoid snapping to zero when the player releases input.
            let speed = length(velocity.linear)
            if speed > 0.1 {
                // atan2 in SpriteKit: right = 0, counter-clockwise positive.
                transform.rotation = atan2(velocity.linear.y, velocity.linear.x)
            }

            // TODO: REMOVE this block once CollisionSystem + wall entities are in place.
            transform.position.x = max(worldBounds.minX, min(worldBounds.maxX, transform.position.x))
            transform.position.y = max(worldBounds.minY, min(worldBounds.maxY, transform.position.y))
        }
    }
}
