//
//  FireEffectSystem.swift
//  dungeonCrawler
//
//  Created by Letian on 11/4/26.
//

import Foundation

public final class FireEffectsSystem: System {
    
    private let destructionQueue: DestructionQueue
    
    public init(destructionQueue: DestructionQueue) {
        self.destructionQueue = destructionQueue
    }

    private let fireTint = SIMD4<Float>(1.0, 0.4, 0.1, 1.0)
    private let defaultTint = SIMD4<Float>(1, 1, 1, 1)

    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)
        let enemies = world.entities(with: EnemyTagComponent.self)
        let players = world.entities(with: PlayerTagComponent.self)
        let targets = enemies + players

        // Reset fire tint each frame
        for target in targets {
            if let sprite = world.getComponent(type: SpriteComponent.self, for: target),
               sprite.tint == fireTint {
                sprite.tint = defaultTint
            }
        }

        for fireZoneEntity in world.entities(with: ZoneComponent.self) {
            guard let zone = world.getComponent(type: ZoneComponent.self, for: fireZoneEntity) else { continue }
            zone.elapsed += dt
            if zone.elapsed >= zone.duration {
                destructionQueue.enqueue(fireZoneEntity)
                continue
            }
            guard let zoneTransform = world.getComponent(type: TransformComponent.self, for: fireZoneEntity) else { continue }
            let zonePos = zoneTransform.position
            let radiusSq = zone.radius * zone.radius
            let frameDamage = zone.damagePerSecond * dt

            for target in targets {
                guard let targetPos = world.getComponent(type: TransformComponent.self, for: target),
                      let health = world.getComponent(type: HealthComponent.self, for: target) else { continue }
                let diff = targetPos.position - zonePos
                if (diff.x * diff.x + diff.y * diff.y) <= radiusSq {
                    health.value.current -= frameDamage
                    health.value.clampToMin()
                    if let sprite = world.getComponent(type: SpriteComponent.self, for: target) {
                        sprite.tint = fireTint
                    }
                }
            }
        }
        destructionQueue.flush(world: world)
    }
}
