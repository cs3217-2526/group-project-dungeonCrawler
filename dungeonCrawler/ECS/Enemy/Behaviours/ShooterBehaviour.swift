//
//  ShooterBehaviour.swift
//  dungeonCrawler
//

import Foundation
import simd

/// Attack behaviour for shooter-type enemies.
///
/// Each frame: aims at the player, writes aimDirection + isShooting into the
/// enemy's InputComponent, and updates FacingComponent so the weapon sprite
/// mirrors correctly. Actual firing is gated by WeaponEffectSystem — this behaviour
/// only signals intent.
///
/// onActivate  — spawns weapon entity, equips it, adds InputComponent +
///               FacingComponent to the enemy if absent.
/// onDeactivate — destroys weapon entity, clears isShooting, removes
///               EquippedWeaponComponent.
///
/// Pair with a movement behaviour (OrbitBehaviour, StationaryBehaviour, etc.)
/// to control where the enemy stands while shooting.
public struct ShooterBehaviour: EnemyBehaviour {

    public var weaponBase: WeaponBase

    public init(weaponBase: WeaponBase = WeaponType.enemyRangedDefault.baseDefinition) {
        self.weaponBase = weaponBase
    }

    // MARK: - Lifecycle

    public func onActivate(entity: Entity, context: BehaviourContext) {
        // Ensure FacingComponent exists before spawning weapon — WeaponEffectSystem reads it
        if context.world.getComponent(type: FacingComponent.self, for: entity) == nil {
            context.world.addComponent(component: FacingComponent(facing: .right), to: entity)
        }

        // Ensure InputComponent exists — this behaviour writes into it every update
        if context.world.getComponent(type: InputComponent.self, for: entity) == nil {
            context.world.addComponent(component: InputComponent(), to: entity)
        }

        // Spawn weapon and link to this enemy as owner
        let weapon = WeaponEntityFactory(base: weaponBase).make(in: context.world, owner: entity)

        // Equip the weapon — WeaponEffectSystem checks EquippedWeaponComponent to decide which weapon fires
        if let equipped = context.world.getComponent(type: EquippedWeaponComponent.self, for: entity) {
            equipped.primaryWeapon = weapon
        } else {
            context.world.addComponent(
                component: EquippedWeaponComponent(primaryWeapon: weapon),
                to: entity)
        }
    }

    public func onDeactivate(entity: Entity, context: BehaviourContext) {
        // Destroy the weapon entity
        if let equipped = context.world.getComponent(type: EquippedWeaponComponent.self, for: entity) {
            context.world.destroyEntity(entity: equipped.primaryWeapon)
            context.world.removeComponent(type: EquippedWeaponComponent.self, from: entity)
        }

        // Clear shoot intent so WeaponEffectSystem doesn't fire on a stale InputComponent
        context.world.getComponent(type: InputComponent.self, for: entity)?.isShooting = false
    }

    // MARK: - Update

    public func update(entity: Entity, context: BehaviourContext) {
        let delta = context.playerPos - context.transform.position
        guard simd_length_squared(delta) > 1e-6,
              let input = context.world.getComponent(type: InputComponent.self, for: entity)
        else { return }

        // Aim at player and signal intent to fire
        input.aimDirection = simd_normalize(delta)
        input.isShooting = true

        // Update facing so the weapon sprite mirrors correctly
        if let facing = context.world.getComponent(type: FacingComponent.self, for: entity),
           let aimFacing = AnimationDirection.from(vector: input.aimDirection) {
            facing.facing = aimFacing
        }
    }
}
