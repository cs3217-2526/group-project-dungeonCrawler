//
//  DamageSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 29/3/26.
//

import Foundation

public final class DamageSystem: System {
    public let priority: Int = 40

    private let events: CollisionEventBuffer
    private let destructionQueue: DestructionQueue

    public init(events: CollisionEventBuffer, destructionQueue: DestructionQueue) {
        self.events = events
        self.destructionQueue = destructionQueue
    }

    public func update(deltaTime: Double, world: World) {
        applyProjectileHits(world: world)
        applyContactDamage(world: world)
    }
    
    // MARK: - Projectile → Enemy
     
    private func applyProjectileHits(world: World) {
        // Deduplicate: ensure each projectile only deals damage once per frame
        // even if it registered multiple overlaps.
        var processedProjectiles = Set<Entity>()
 
        for event in events.projectileHitEnemy {
            guard world.isAlive(entity: event.projectile),
                  world.isAlive(entity: event.enemy) else { continue }
 
            if !processedProjectiles.contains(event.projectile) {
                world.modifyComponentIfExist(type: HealthComponent.self, for: event.enemy) { health in
                    health.value.current -= event.damage
                    health.value.clampToMin()
                }
                processedProjectiles.insert(event.projectile)
            }
 
            destructionQueue.enqueue(event.projectile)
        }
    }
 
    // MARK: - Enemy contact → Player

    private func applyContactDamage(world: World) {
        for event in events.playerHitByEnemy {
            guard world.isAlive(entity: event.player) else { continue }

            // Skip if entity is currently in invincibility frames
            guard world.getComponent(type: InvincibilityComponent.self, for: event.player) == nil else { continue }

            world.modifyComponentIfExist(type: HealthComponent.self, for: event.player) { health in
                health.value.current -= event.damage
                health.value.clampToMin()
            }

            // Grant invincibility frames so the next collision hit doesn't immediately deal damage again
            world.addComponent(component: InvincibilityComponent(remainingTime: 0.5), to: event.player)
        }
    }
}
