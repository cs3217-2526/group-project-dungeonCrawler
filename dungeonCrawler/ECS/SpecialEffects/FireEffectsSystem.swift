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

    public func update(deltaTime: Double, world: World) {
        for (fireZoneEntity) in world.entities(with: FireZoneComponent.self) {
            guard let fireZoneComponent = world.getComponent(type: FireZoneComponent.self, for: fireZoneEntity) else { return }
            fireZoneComponent.elapsed += Float(deltaTime)
            if fireZoneComponent.elapsed >= fireZoneComponent.duration {
                destructionQueue.enqueue(fireZoneEntity)
            }
        }
        destructionQueue.flush(world: world)
    }
}
