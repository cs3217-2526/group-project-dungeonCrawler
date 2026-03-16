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

    /// Used only when an entity has no StatsComponent; keeps the system safe for non-stat entities.
    public var fallbackMoveSpeed: Float = 90

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

        for (entity, input, _) in movable {
            let speed: Float
            if let sc = world.getComponent(type: StatsComponent.self, for: entity),
               let sv = sc.value(for: .moveSpeed) {
                speed = sv.current
            } else {
                speed = fallbackMoveSpeed
            }
            world.modifyComponent(type: VelocityComponent.self, for: entity) { velocity in
                velocity.linear = input.moveDirection * speed
            }
            
            guard let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
            else { continue }

            world.modifyComponent(type: TransformComponent.self, for: entity) { transform in
                
                // Integrate velocity into position.
                transform.position += velocity.linear * dt
                
                transform.position.x = max(worldBounds.minX, min(worldBounds.maxX, transform.position.x))
                transform.position.y = max(worldBounds.minY, min(worldBounds.maxY, transform.position.y))
            }
        }
    }
}
