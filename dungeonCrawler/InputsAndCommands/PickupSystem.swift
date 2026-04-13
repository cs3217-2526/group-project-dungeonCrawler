//
//  PickupSystem.swift
//  dungeonCrawler
//
//  Created by Letian on 4/4/26.
//

import Foundation
import simd

public final class PickupSystem: System {
    public var dependencies: [System.Type] { [] }

    private let commandQueues: CommandQueues
    private let pickupRange: Float
    private let defaultWeaponOffset: SIMD2<Float>

    public init(
        commandQueues: CommandQueues,
        pickupRange: Float = 60,
        defaultWeaponOffset: SIMD2<Float> = SIMD2<Float>(10, -5)
    ) {
        self.commandQueues = commandQueues
        self.pickupRange = pickupRange
        self.defaultWeaponOffset = defaultWeaponOffset
    }

    public func update(deltaTime: Double, world: World) {
        while commandQueues.pop(PickupCommand.self) != nil {
            for (player, _, equipped, playerTransform) in world.entities(
                with: PlayerTagComponent.self,
                and: EquippedWeaponComponent.self,
                and: TransformComponent.self
            ) {
                guard let pickedWeapon = nearestDroppedWeapon(
                    to: playerTransform.position,
                    within: pickupRange,
                    in: world
                ) else { continue }

                let ownerFacing = world.getComponent(type: FacingComponent.self, for: player)?.facing ?? .right

                world.removeComponent(type: SpriteComponent.self, from: pickedWeapon)
                if let secondWeapon = equipped.secondaryWeapon {
                    world.removeComponent(type: OwnerComponent.self, from: secondWeapon)
                    guard let renderInfo = world.getComponent(type: WeaponRenderComponent.self, for: secondWeapon) else { fatalError("secondWeapon missing WeaponRenderComponent") }
                    world.addComponent(component: SpriteComponent(textureName: renderInfo.textureName), to: secondWeapon)
                }
                equipped.secondaryWeapon = pickedWeapon
                world.addComponent(
                    component: OwnerComponent(ownerEntity: player),
                    to: pickedWeapon
                )
                world.addComponent(component: FacingComponent(facing: ownerFacing), to: pickedWeapon)
            }
        }
    }

    private func nearestDroppedWeapon(
        to position: SIMD2<Float>,
        within maxDistance: Float,
        in world: World
    ) -> Entity? {
        let maxDistanceSquared = maxDistance * maxDistance
        var nearestEntity: Entity?
        var nearestDistanceSquared = Float.greatestFiniteMagnitude

        for (weapon, transform, _, _) in world.entities(
            with: TransformComponent.self,
            and: WeaponEffectsComponent.self,
            and: WeaponRenderComponent.self
        ) {
            guard world.getComponent(type: OwnerComponent.self, for: weapon) == nil else { continue }

            let distanceSquared = simd_length_squared(transform.position - position)
            guard distanceSquared <= maxDistanceSquared else { continue }
            guard distanceSquared < nearestDistanceSquared else { continue }

            nearestDistanceSquared = distanceSquared
            nearestEntity = weapon
        }

        return nearestEntity
    }
}
