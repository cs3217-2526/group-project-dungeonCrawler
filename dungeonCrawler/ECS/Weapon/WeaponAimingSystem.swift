//
//  WeaponAimingSystem.swift
//  dungeonCrawler
//
//  Created by Letian on 19/4/26.
//

import Foundation

public final class WeaponAimingSystem: System {
    public var dependencies: [System.Type] { [CollisionSystem.self] }
    private var gameTime: Float

    public init() {
        self.gameTime = 0
    }
    
    public func update(deltaTime: Double, world: World) {
        self.gameTime += Float(deltaTime)
        let delta = Float(deltaTime)
        for (weaponEntity, ownerComponent, _, weaponRenderComponent) in world.entities(
            with: OwnerComponent.self,
            and: TransformComponent.self,
            and: WeaponRenderComponent.self
        ) {
            let ownerEntity = ownerComponent.ownerEntity
            if let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: ownerEntity),
               equipped.primaryWeapon != weaponEntity {
                continue
            }
        }
    }
}
