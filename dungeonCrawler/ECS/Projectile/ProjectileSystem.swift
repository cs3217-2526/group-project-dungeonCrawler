//
//  ProjectileSystem.swift
//  dungeonCrawler
//
//  Created by Letian on 20/3/26.
//

import Foundation
import simd

public final class ProjectileSystem: System {
    public var dependencies: [System.Type] { [WeaponSystem.self] }
    
    private let events: CollisionEventBuffer
    private let destructionQueue: DestructionQueue
 
    public init(events: CollisionEventBuffer, destructionQueue: DestructionQueue) {
        self.events = events
        self.destructionQueue = destructionQueue
    }
    
    private func updateVelocityInTwoD(velocity: inout VelocityComponent, gravity: GravityComponent) {
        
    }
    
    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)
        for (projectileEntity, projectileComponent, velocityComponent, _, rangeComponent) in world.entities(
            with: ProjectileComponent.self,
            and: VelocityComponent.self,
            and: TransformComponent.self,
            and: EffectiveRangeComponent.self) {

            // Apply gravity for parabolic projectiles (e.g. rockets)
            if let gravityComp = world.getComponent(type: GravityComponent.self, for: projectileEntity) {
                velocityComponent.linear.y -= gravityComp.gravity * dt
                // Update rotation to follow the arc
                let goingRight = velocityComponent.linear.x >= 0
                let newRotation: Float = goingRight
                    ? atan2(velocityComponent.linear.y, velocityComponent.linear.x)
                    : -atan2(velocityComponent.linear.y, -velocityComponent.linear.x)
                world.getComponent(type: TransformComponent.self, for: projectileEntity)?.rotation = newRotation
            }

            world.getComponent(type: TransformComponent.self, for: projectileEntity)?.position += velocityComponent.linear * dt
            let distanceTraveled = simd_length(velocityComponent.linear) * dt

            rangeComponent.value.current -= distanceTraveled

            // Range expiry — no specific target was hit
            if rangeComponent.value.current <= 0 {
                let pos = world.getComponent(type: TransformComponent.self, for: projectileEntity)?.position ?? .zero
                destructionQueue.enqueue(projectileEntity)
                let context = HitContext(center: pos, world: world, target: nil, zoneBase: nil)
                for effect in projectileComponent.hitEffects {
                    effect.apply(context: context)
                }
            }
        }

        // Projectile hit a solid wall — no target entity, no zone
        let hitSolidProjectiles = Set(events.projectileHitSolid.map { $0.projectile.id })
        for id in hitSolidProjectiles {
            let entity = Entity(id: id)
            guard world.isAlive(entity: entity) else { continue }
            let pos = world.getComponent(type: TransformComponent.self, for: entity)?.position ?? .zero
            
            guard let projectileComponent = world.getComponent(type: ProjectileComponent.self, for: entity) else { continue }
            let context = HitContext(center: pos, world: world, target: nil, zoneBase: nil)
            for effect in projectileComponent.hitEffects {
                effect.apply(context: context)
            }
            destructionQueue.enqueue(entity)
        }

        // Projectile hit an enemy — run hit effects only.
        // Damage application and projectile destruction are handled by DamageSystem.
        for event in events.projectileHitEnemy {
            let entity = event.projectile
            guard world.isAlive(entity: entity) else { continue }
            let pos = world.getComponent(type: TransformComponent.self, for: entity)?.position ?? .zero
            guard let projectileComponent = world.getComponent(type: ProjectileComponent.self, for: entity) else { continue }
            let context = HitContext(center: pos, world: world, target: event.enemy, zoneBase: nil)
            for effect in projectileComponent.hitEffects {
                effect.apply(context: context)
            }
        }

        destructionQueue.flush(world: world)
    }
}
