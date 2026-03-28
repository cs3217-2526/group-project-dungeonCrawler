//
//  InputSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

// MARK: - InputProvider protocol

/// Abstracts the source of raw input so the system is hardware-agnostic.
public protocol JoyStickInputProvider: AnyObject {
    var rawMoveVector: SIMD2<Float> { get }

    var rawAimVector: SIMD2<Float> { get }

    var isShootPressed: Bool { get }
}

// MARK: - InputSystem

public final class InputSystem: System {

    public let priority: Int = 10

    private weak var joyStickInputProvider: JoyStickInputProvider?
    private let commandQueues: CommandQueues

    public init(joyStickInputProvider: JoyStickInputProvider, commandQueues: CommandQueues) {
        self.joyStickInputProvider = joyStickInputProvider
        self.commandQueues = commandQueues
    }

    public func update(deltaTime: Double, world: World) {
        guard let moveAndAimProvider = joyStickInputProvider else { return }

        let moveDirection = moveAndAimProvider.rawMoveVector
        let aimDirection  = moveAndAimProvider.rawAimVector
        let shooting      = moveAndAimProvider.isShootPressed

        for entity in world.entities(with: InputComponent.self) {
            guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }

            world.modifyComponent(type: InputComponent.self, for: entity) { input in
                input.moveDirection = moveDirection
                input.aimDirection  = aimDirection
                input.isShooting    = shooting
            }

            // Update facing: aim direction takes priority over move direction when aim input is present.
            let facingX: Float = aimDirection.x != 0 ? aimDirection.x : moveDirection.x
            guard facingX != 0 else { continue }
            world.modifyComponent(type: FacingComponent.self, for: entity) { facing in
                facing.facing = facingX > 0 ? .right : .left
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
                if let weapon = world.getComponent(type: WeaponComponent.self, for: newPrimary) {
                    world.addComponent(
                        component: SpriteComponent(content: .texture(name: weapon.type.textureName), layer: .weapon),
                        to: newPrimary
                    )
                }

                world.modifyComponent(type: EquippedWeaponComponent.self, for: entity) { e in
                    e.primaryWeapon = newPrimary
                    e.secondaryWeapon = oldPrimary
                }
            }
        }
    }
}
