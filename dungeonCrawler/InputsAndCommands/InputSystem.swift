//
//  InputSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

// MARK: - InputSystem

public final class InputSystem: System {

    public var dependencies: [System.Type] { [] }

    private let commandQueues: CommandQueues

    public init(commandQueues: CommandQueues) {
        self.commandQueues = commandQueues
    }

    public func update(deltaTime: Double, world: World) {
        var finalMoveVector: SIMD2<Float>? = nil
        while let moveCommand = commandQueues.pop(MoveCommand.self) {
            for entity in world.entities(with: InputComponent.self) {
                guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }
                world.getComponent(type: InputComponent.self, for: entity)?.moveDirection = moveCommand.rawMoveVector
            }
            finalMoveVector = moveCommand.rawMoveVector
        }

        while let aimCommand = commandQueues.pop(AimCommand.self) {
            let aimDirection = aimCommand.rawAimVector
            for entity in world.entities(with: InputComponent.self) {
                guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }
                world.getComponent(type: InputComponent.self, for: entity)?.aimDirection = aimDirection
                // Update facing: aim direction takes priority over move direction when aim input is present.
                let facingVector: SIMD2<Float> = simd_length(aimDirection) > 0.001 ? aimDirection : (finalMoveVector ?? .zero)
                guard let newFacing = FacingType.from(vector: facingVector) else { continue }
                world.getComponent(type: FacingComponent.self, for: entity)?.facing = newFacing
            }
        }

        while let fireCommand = commandQueues.pop(FireCommand.self) {
            let isShooting = fireCommand.shooting
            for entity in world.entities(with: InputComponent.self) {
                guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }
                world.getComponent(type: InputComponent.self, for: entity)?.isShooting = isShooting
            }
        }

        while commandQueues.pop(SwitchWeaponCommand.self) != nil {
            for entity in world.entities(with: EquippedWeaponComponent.self) {
                guard let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: entity),
                      let newPrimary = equipped.secondaryWeapon else { continue }

                let oldPrimary = equipped.primaryWeapon

                // Hide old primary by removing its sprite
                world.removeComponent(type: SpriteComponent.self, from: oldPrimary)

                // Show new primary by restoring its sprite
                if let render = world.getComponent(type: WeaponRenderComponent.self, for: newPrimary) {
                    world.addComponent(
                        component: SpriteComponent(
                            content: .texture(name: render.textureName),
                            layer: .weaponFront,
                            anchorPoint: render.anchorPoint,
                        ),
                        to: newPrimary
                    )
                }

                if let weapon = world.getComponent(type: EquippedWeaponComponent.self, for: entity) {
                    weapon.primaryWeapon = newPrimary
                    weapon.secondaryWeapon = oldPrimary
                }
            }
        }
    }
}
