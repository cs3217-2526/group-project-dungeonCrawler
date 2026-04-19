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

            let stalled = input.isShooting && isChargingWeapon(owner: entity, world: world)
            let desiredDirection = stalled ? .zero : input.moveDirection
            world.getComponent(type: VelocityComponent.self, for: entity)?.linear = desiredDirection * moveSpeed.value.current

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

    /// Owner's primary weapon stalls movement while it is winding up a charged attack.
    private func isChargingWeapon(owner: Entity, world: World) -> Bool {
        guard let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: owner) else { return false }
        return world.getComponent(type: WeaponChargeComponent.self, for: equipped.primaryWeapon) != nil
    }
}
