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
    //   • HealthComponent     — current/max HP; entity destroyed at 0
    //   • MoveSpeedComponent  — scalar speed used by MovementSystem
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
        do {
            try world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: scale), to: entity)
            try world.addComponent(component: VelocityComponent(), to: entity)
            try world.addComponent(component: InputComponent(), to: entity)
            try world.addComponent(component: SpriteComponent(textureName: textureName), to: entity)
            try world.addComponent(component: PlayerTagComponent(), to: entity)
            try world.addComponent(component: HealthComponent(base: 100), to: entity)
            try world.addComponent(component: MoveSpeedComponent(base: 90), to: entity)
        } catch {
            fatalError("Error adding component to player entity: \(error)")
        }

        return entity
    }

    // MARK: - Enemy
    //
    // Components attached:
    //   • TransformComponent  — position, rotation, scale
    //   • SpriteComponent     — visual representation
    //   • EnemyTagComponent   — marks this as an enemy and holds its type
    //
    // Future additions:
    //   • HealthComponent      — current / max health
    //   • CombatStatsComponent — attack damage, attack speed
    //   • AIComponent          — movement behaviour state machine

    @discardableResult
    public static func makeEnemy(
        in world: World,
        at position: SIMD2<Float>,
        type: EnemyType,
        scale: Float = 1
    ) -> Entity {
        let entity = world.createEntity()
        do {
            try world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: scale), to: entity)
            try world.addComponent(component: SpriteComponent(textureName: type.textureName), to: entity)
            try world.addComponent(component: EnemyTagComponent(enemyType: type), to: entity)
        } catch {
            fatalError("Error adding component to enemy entity: \(error)")
        }

        return entity
    }
}
