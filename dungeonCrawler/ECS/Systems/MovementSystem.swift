//
//  MovementSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

public final class MovementSystem: System {

    public var dependencies: [System.Type] { [InputSystem.self, EnemyAISystem.self, KnockbackSystem.self] }

    public init() {}

    // MARK: - Update

    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)

        let movable = world.entities(
            with: InputComponent.self,
            and: VelocityComponent.self,
            and: MoveSpeedComponent.self
        )

        for (entity, input, _, moveSpeed) in movable {
            guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }

            world.getComponent(type: VelocityComponent.self, for: entity)?.linear = input.moveDirection * moveSpeed.value.current
            
            guard let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
            else { continue }

            world.getComponent(type: TransformComponent.self, for: entity)?.position += velocity.linear * dt
        }

        // Integrate velocity for enemies (velocity is set by EnemyAISystem)
        let enemyMovable = world.entities(
            with: EnemyStateComponent.self,
            and: VelocityComponent.self,
            and: TransformComponent.self)

        for (entity, _, velocity, _) in enemyMovable {
            guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }

            world.getComponent(type: TransformComponent.self, for: entity)?.position += velocity.linear * dt
        }
    }
}
