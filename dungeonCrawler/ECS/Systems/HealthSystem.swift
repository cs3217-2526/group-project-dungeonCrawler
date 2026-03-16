//
//  HealthSystem.swift
//  dungeonCrawler
//

import Foundation

/// Destroys any entity whose health stat has dropped to or below zero.
/// Agnostic to how damage was applied (another system)
public final class HealthSystem: System {
    public let priority: Int = 15

    public func update(deltaTime: Double, world: World) {
        for entity in world.entities(with: StatsComponent.self) {
            guard let stats = world.getComponent(type: StatsComponent.self, for: entity),
                  let health = stats.value(for: .health),
                  health.current <= 0 else { continue }
            world.destroyEntity(entity: entity)
        }
    }
}
