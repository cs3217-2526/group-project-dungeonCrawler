//
//  EntityFactory.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

public enum EntityFactory {
    
    // MARK: - Player
    //
    // Components attached:
    //   • TransformComponent  — position, rotation, scale
    //   • VelocityComponent   — movement vector (starts at zero)
    //   • InputComponent      — intent from InputSystem
    //   • SpriteComponent     — visual representation
    //   • PlayerTag           — marks this as the human-controlled entity
    //   • StatsComponent      — health, moveSpeed, attack, defence
    //
    // Future additions:
    //   • WeaponSlotComponent — which weapon is equipped
    //   • AnimationComponent  — walk / idle / attack animation state machine
    
    @discardableResult
    public static func makePlayer(
        in world: World,
        at position: SIMD2<Float>,
        textureName: String = "knight", // set to knight for now
        scale: Float = 1
    ) -> Entity {
        let entity = world.createEntity()
        
        world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: scale), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(), to: entity)
        world.addComponent(component: SpriteComponent(textureName: textureName), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        world.addComponent(
            component: StatsComponent(stats: [
                .health:    StatValue(base: 100, max: 100),
                .moveSpeed: StatValue(base: 90),
                .attack:    StatValue(base: 10),
                .defence:   StatValue(base: 0)
            ]),
            to: entity
        )

        return entity
    }
}
