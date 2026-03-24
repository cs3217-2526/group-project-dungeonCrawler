//
//  PlayerEntityFactory.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 24/3/26.
//

import Foundation
import simd

// Components attached:
//   • TransformComponent     — position, rotation, scale
//   • VelocityComponent      — movement vector (starts at zero)
//   • InputComponent         — intent from InputSystem
//   • SpriteComponent        — visual representation
//   • PlayerTag              — marks this as the human-controlled entity
//   • HealthComponent        — current/max HP; entity destroyed at 0
//   • MoveSpeedComponent     — scalar speed used by MovementSystem
//   • CollisionBoxComponent  — axis-aligned bounding box for collision
//   • MassComponent          — current mass used by KnockbackSystem
//
// Future additions:
//   • WeaponSlotComponent    — which weapon is equipped
//   • AnimationComponent     — walk / idle / attack animation state machine

public struct PlayerEntityFactory: EntityFactory {
    let position: SIMD2<Float>
    let textureName: String
    let scale: Float

    public init(
        at position: SIMD2<Float>,
        textureName: String = "knight", // set to knight for now
        scale: Float = 1
    ) {
        self.position = position
        self.textureName = textureName
        self.scale = scale
    }

    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()

        world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: scale), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(), to: entity)
        world.addComponent(component: SpriteComponent(textureName: textureName), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2<Float>(28, 28)), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 90), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2(48 * scale, 48 * scale)), to: entity)
        world.addComponent(component: FacingComponent(), to: entity)
        world.addComponent(component: MassComponent(), to: entity)

        return entity
    }
}
