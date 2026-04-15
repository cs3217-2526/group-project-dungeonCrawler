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
            var remainingRange: Float = .greatestFiniteMagnitude

            rangeComponent.value.current -= distanceTraveled
            remainingRange = rangeComponent.value.current

            if remainingRange <= 0 {
                let pos = world.getComponent(type: TransformComponent.self, for: projectileEntity)?.position ?? .zero
                destructionQueue.enqueue(projectileEntity)
                for effect in projectileComponent.hitEffects {
                    effect.apply(
                        context: ZoneContext(center: pos, world: world,
                                             zoneBase: HitEffectsLibrary.fireZone.effectDefinition))
                }
            }
        }
        
        let hitProjectiles = Set(events.projectileHitSolid.map { $0.projectile.id })
        for id in hitProjectiles {
            let entity = Entity(id: id)
            guard world.isAlive(entity: entity) else { continue }
            let pos = world.getComponent(type: TransformComponent.self, for: entity)?.position ?? .zero
            guard let projectileComponent = world.getComponent(type: ProjectileComponent.self, for: entity) else { continue }
            for effect in projectileComponent.hitEffects {
                effect.apply(
                    context: ZoneContext(center: pos, world: world,
                                         zoneBase: HitEffectsLibrary.fireZone.effectDefinition))
            }
            destructionQueue.enqueue(entity)
        }
        destructionQueue.flush(world: world)
    }
}
