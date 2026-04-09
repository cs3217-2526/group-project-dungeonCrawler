//
//  KnockbackSystem.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 19/3/26.
//

import Foundation
import simd

public final class KnockbackSystem: System {
    public var dependencies: [System.Type] { [] }

    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)
        for entity in world.entities(with: KnockbackComponent.self) {
            guard let kb = world.getComponent(type: KnockbackComponent.self, for: entity) else { continue }

            world.getComponent(type: TransformComponent.self, for: entity)?.position += kb.velocity * dt
            kb.remainingTime -= dt

            if kb.remainingTime <= 0 {
                world.removeComponent(type: KnockbackComponent.self, from: entity)
            }
        }
    }
}
