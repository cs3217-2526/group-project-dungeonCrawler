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
// Notes:
//   • WeaponSlotComponent    — (future) which weapon is equipped
//   • AnimationComponent     — added by GameScene after spawn, once the character sheet is loaded

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
        world.addComponent(component: SpriteComponent(
            content: .texture(name: textureName),
            layer: .entity
        ), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        world.addComponent(component: ManaComponent(base: 100, max: 100, regenRate: 2), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 180), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2(WorldConstants.playerSize * scale, WorldConstants.playerSize * scale)), to: entity)
        world.addComponent(component: FacingComponent(), to: entity)
        world.addComponent(component: MassComponent(), to: entity)

        return entity
    }
}
