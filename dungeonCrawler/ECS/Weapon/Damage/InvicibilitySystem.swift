//
//  InvicibilitySystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 29/3/26.
//

import Foundation

/// Ticks down InvincibilityComponent.remainingTime each frame.
/// Removes the component once the timer expires, allowing the entity to take damage again.
public final class InvincibilitySystem: System {
    public let priority: Int = 45  // runs after DamageSystem (40)
 
    public init() {}
 
    public func update(deltaTime: Double, world: World) {
        for entity in world.entities(with: InvincibilityComponent.self) {
            guard var invincibility = world.getComponent(type: InvincibilityComponent.self, for: entity)
            else { continue }
 
            invincibility.remainingTime -= Float(deltaTime)
 
            if invincibility.remainingTime <= 0 {
                world.removeComponent(type: InvincibilityComponent.self, from: entity)
            } else {
                world.modifyComponentIfExist(type: InvincibilityComponent.self, for: entity) {
                    $0.remainingTime = invincibility.remainingTime
                }
            }
        }
    }
}
