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
    
    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)
        for (projectileEntity, _, velocityComponent, _, _) in world.entities(
            with: ProjectileComponent.self,
            and: VelocityComponent.self,
            and: TransformComponent.self,
            and: EffectiveRangeComponent.self) {
            world.modifyComponentIfExist(type: TransformComponent.self, for: projectileEntity) { transform in
                transform.position += velocityComponent.linear * dt
            }
            let distanceTraveled = simd_length(velocityComponent.linear) * dt
            var remainingRange: Float = .greatestFiniteMagnitude
            world.modifyComponentIfExist(type: EffectiveRangeComponent.self, for: projectileEntity) { rangeComponent in
                rangeComponent.value.current -= distanceTraveled
                remainingRange = rangeComponent.value.current
            }
            if remainingRange <= 0 {
                destructionQueue.enqueue(projectileEntity)
            }
        }
        
        let hitProjectiles = Set(events.projectileHitSolid.map { $0.projectile.id })
        for id in hitProjectiles {
            let entity = Entity(id: id)
            guard world.isAlive(entity: entity) else { continue }
            destructionQueue.enqueue(entity)
        }
        destructionQueue.flush(world: world)
    }
}
