//
//  HealthSystem.swift
//  dungeonCrawler
//
//  Created by Ger Teck on 16/3/26.
//

import Foundation

public final class HealthSystem: System {

    public var dependencies: [System.Type] { [EnemyAISystem.self] }

    public init() {}

    public func update(deltaTime: Double, world: World) {
        for entity in world.entities(with: HealthComponent.self) {
            guard let health = world.getComponent(type: HealthComponent.self, for: entity)
            else { continue }

            if health.value.current <= 0 {
                world.destroyEntity(entity: entity)
            }
        }
    }
}
