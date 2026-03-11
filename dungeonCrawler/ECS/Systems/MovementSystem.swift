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
    public var defaultMoveSpeed: Float = 90

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
            world.modifyComponent(type: VelocityComponent.self, for: entity) { velocity in
                velocity.linear = input.moveDirection * defaultMoveSpeed
            }
            
            guard let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
            else { continue }

            world.modifyComponent(type: TransformComponent.self, for: entity) { transform in
                
                // Integrate velocity into position.
                transform.position += velocity.linear * dt
                
                transform.position.x = floor(transform.position.x)
                transform.position.y = floor(transform.position.y)
                
                transform.position.x = max(worldBounds.minX, min(worldBounds.maxX, transform.position.x))
                transform.position.y = max(worldBounds.minY, min(worldBounds.maxY, transform.position.y))
            }
        }
    }
}
