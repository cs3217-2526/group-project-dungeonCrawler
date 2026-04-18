//
//  SlowSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 19/4/26.
//

import Foundation

/// Ticks SlowComponent timers each frame.
/// While SlowComponent is present, VelocityComponent.linear is scaled by the
/// multiplier inside EnemyAISystem (or wherever velocity is written) — this system
/// only manages lifetime and removal.
public final class SlowSystem: System {
    public var dependencies: [System.Type] { [] }
 
    private let slowTint    = SIMD4<Float>(0.3, 0.6, 1.0, 1.0)
    private let defaultTint = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
 
    public init() {}
 
    public func update(deltaTime: Double, world: World) {
        let dt = Float(deltaTime)
        for entity in world.entities(with: SlowComponent.self) {
            guard let slow = world.getComponent(type: SlowComponent.self, for: entity) else { continue }
            slow.remaining -= dt
            if slow.remaining <= 0 {
                world.removeComponent(type: SlowComponent.self, from: entity)
                world.getComponent(type: SpriteComponent.self, for: entity)?.tint = defaultTint
            } else {
                world.getComponent(type: SpriteComponent.self, for: entity)?.tint = slowTint
            }
        }
    }
}
 
