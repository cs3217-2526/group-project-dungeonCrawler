//
//  WeaponDropSystem.swift
//  dungeonCrawler
//
//  Created by Letian on 4/4/26.
//

import Foundation
import simd

public final class WeaponDropSystem: System {
    public var dependencies: [System.Type] { [] }

    private let commandQueues: CommandQueues

    public init(commandQueues: CommandQueues) {
        self.commandQueues = commandQueues
    }
    
    /// Only drop if there is a secondary weapon
    /// (reason: cannot have no weapon)
    public func update(deltaTime: Double, world: World) {
        while commandQueues.pop(DropWeaponCommand.self) != nil {
            for entity in world.entities(with: EquippedWeaponComponent.self) {
                guard let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: entity),
                      let secondaryWeapon = equipped.secondaryWeapon,
                      let secondaryWeaponRender = world.getComponent(type: WeaponRenderComponent.self, for: secondaryWeapon) else {
                    continue
                }
                let oldPrimary = equipped.primaryWeapon
                world.removeComponent(type: OwnerComponent.self, from: oldPrimary)
                world.removeComponent(type: FacingComponent.self, from: oldPrimary)
                world.addComponent(
                    component: SpriteComponent(
                        content: .texture(name: secondaryWeaponRender.textureName),
                        layer: .weaponFront,
                        anchorPoint: secondaryWeaponRender.anchorPoint),
                    to: secondaryWeapon)
                if let equippedWeapons = world.getComponent(type: EquippedWeaponComponent.self, for: entity) {
                    equippedWeapons.primaryWeapon = secondaryWeapon
                    equippedWeapons.secondaryWeapon = nil
                }
            }
        }
    }
}
