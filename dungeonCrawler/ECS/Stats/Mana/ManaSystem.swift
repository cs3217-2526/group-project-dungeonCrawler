//
//  ManaSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 31/3/26.
//

import Foundation

public final class ManaSystem: System {
    
    public var dependencies: [System.Type] { [] }
    
    public init() {}
    
    public func update(deltaTime: Double, world: World) {
        for entity in world.entities(with: ManaComponent.self) {
            guard var mana = world.getComponent(type: ManaComponent.self, for: entity)
            else { continue }
            
            guard mana.regenRate > 0 else { continue }
            
            // Only regen if not already at max
            let max = mana.value.max ?? mana.value.base
            guard mana.value.current < max else { continue }
            
            world.modifyComponentIfExist(type: ManaComponent.self, for: entity) { m in
                m.value.current += m.regenRate * Float(deltaTime)
                m.value.clampToMax()
            }
        }
    }
}
