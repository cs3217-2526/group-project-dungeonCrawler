//
//  ProjectileEntityFactory.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 24/3/26.
//

import Foundation
import simd

public struct ProjectileEntityFactory: EntityFactory {
    let position: SIMD2<Float>
    let direction: SIMD2<Float>
    let speed: Float
    let effectiveRange: Float
    let damage: Float
    let owner: Entity
    let spriteName: String
    let collisionBoxSize: SIMD2<Float>
    let hitEffects: [any ProjectileHitEffect]

    public init(
        from position: SIMD2<Float>,
        aimAt direction: SIMD2<Float>,
        speed: Float,
        effectiveRange: Float,
        damage: Float = 10,
        owner: Entity,
        spriteName: String = "normalHandgunBullet",
        collisionBoxSize: SIMD2<Float> = SIMD2<Float>(6, 6),
        hitEffects: [any ProjectileHitEffect]?
    ) {
        self.position = position
        self.direction = direction
        self.speed = speed
        self.effectiveRange = effectiveRange
        self.damage = damage
        self.owner = owner
        self.spriteName = spriteName
        self.collisionBoxSize = collisionBoxSize
        self.hitEffects = hitEffects ?? []
    }

    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()
        let goingRight = direction.x >= 0
        let bulletRotation: Float = goingRight
            ? atan2(direction.y, direction.x)
            : -atan2(direction.y, -direction.x)
        world.addComponent(component: TransformComponent(position: position, rotation: bulletRotation, scale: 1), to: entity)
        world.addComponent(component: VelocityComponent(linear: direction * speed), to: entity)
        world.addComponent(component: SpriteComponent(content: .texture(name: spriteName), layer: .projectile), to: entity)
        world.addComponent(component: ProjectileComponent(hitEffects: hitEffects), to: entity)
        world.addComponent(component: OwnerComponent(ownerEntity: owner), to: entity)
        world.addComponent(component: EffectiveRangeComponent(base: effectiveRange), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: collisionBoxSize), to: entity)
        world.addComponent(component: ContactDamageComponent(damage: damage), to: entity)
        return entity
    }
}
