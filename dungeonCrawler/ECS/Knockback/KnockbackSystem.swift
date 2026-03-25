//
//  KnockbackSystem.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 19/3/26.
//

import Foundation
import simd

public final class KnockbackSystem: System {
    public let priority: Int = 12

    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)
        for entity in world.entities(with: KnockbackComponent.self) {
            guard let kb = world.getComponent(type: KnockbackComponent.self, for: entity) else { continue }

            world.modifyComponent(type: TransformComponent.self, for: entity) { transform in
                transform.position += kb.velocity * dt
            }
            world.modifyComponent(type: KnockbackComponent.self, for: entity) { $0.remainingTime -= dt }

            if let kb = world.getComponent(type: KnockbackComponent.self, for: entity), kb.remainingTime <= 0 {
                world.removeComponent(type: KnockbackComponent.self, from: entity)
            }
        }
    }
}
