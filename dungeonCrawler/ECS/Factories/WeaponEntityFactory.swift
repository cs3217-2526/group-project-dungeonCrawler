//
//  WeaponEntityFactory.swift
//  dungeonCrawler
//

import Foundation
import simd

public struct WeaponEntityFactory: EntityFactory {
    let textureName: String
    let offset: SIMD2<Float>
    let scale: Float
    let lastFiredAt: Float
    let coolDownIntervel: TimeInterval?
    let attackSpeed: Float?
    let effects: [any WeaponEffect]
    let anchorPoint: SIMD2<Float>
    let initRotation: Float
    /// Carried through from WeaponBase so make() can attach WeaponAmmoComponent.
    let ammoConfig: AmmoConfig?

    public init(base: WeaponBase) {
        self.textureName = base.textureName
        self.offset = base.offset
        self.scale = base.scale
        self.lastFiredAt = base.lastFiredAt ?? 0
        self.coolDownIntervel = base.cooldown
        self.attackSpeed = base.attackSpeed
        self.effects = base.effects
        self.anchorPoint = base.anchorPoint ?? SIMD2<Float>(0.5, 0.5)
        self.initRotation = base.initRotation ?? 0
        self.ammoConfig = base.ammoConfig
    }

    /// Components added to every weapon entity regardless of spawn context:
    ///   WeaponTimingComponent, WeaponRenderComponent, WeaponEffectsComponent
    ///   WeaponAmmoComponent   (firearms only — when ammoConfig is non-nil)
    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()

        world.addComponent(
            component: WeaponTimingComponent(
                lastFiredAt: lastFiredAt,
                coolDownInterval: coolDownIntervel,
                attackSpeed: attackSpeed),
            to: entity)
        world.addComponent(
            component: WeaponRenderComponent(
                textureName: textureName,
                anchorPoint: anchorPoint,
                initRotation: initRotation,
                offset: offset),
            to: entity)
        world.addComponent(
            component: WeaponEffectsComponent(effects: effects),
            to: entity)

        // Attach ammo state for firearms; spellbooks and melee leave this nil.
        if let ammoConfig {
            world.addComponent(
                component: WeaponAmmoComponent(
                    magazineSize: ammoConfig.magazineSize,
                    reloadTime: ammoConfig.reloadTime),
                to: entity)
        }

        // Attach charge state for weapons that gate firing behind a ChargeEffect.
        for effect in effects {
            if let charge = effect as? ChargeEffect {
                world.addComponent(
                    component: WeaponChargeComponent(required: charge.required),
                    to: entity)
                break
            }
        }

        return entity
    }
    
    public func make(in world: World, initLocation: SIMD2<Float>) -> Entity {
        let entity = make(in: world)
        world.addComponent(
            component: TransformComponent(
                position: initLocation + offset,
                rotation: initRotation,
                scale: scale),
            to: entity)
        return entity
    }
    
    /// Use this for any owner entity — player or enemy.
    /// Attaches OwnerComponent, FacingComponent, and TransformComponent to the weapon.
    public func make(in world: World, owner: Entity) -> Entity {
        let entity = make(in: world)
        let ownerFacing = world.getComponent(type: FacingComponent.self, for: owner)?.facing ?? .right
        let initLocation = world.getComponent(type: TransformComponent.self, for: owner)?.position ?? .zero
        world.addComponent(component: FacingComponent(facing: ownerFacing), to: entity)
        world.addComponent(component: OwnerComponent(ownerEntity: owner), to: entity)
        world.addComponent(component: TransformComponent(position: initLocation + offset, rotation: initRotation, scale: scale), to: entity)
        return entity
    }

    /// Convenience alias so existing player call sites keep compiling unchanged.
    public func make(in world: World, player: Entity) -> Entity {
        make(in: world, owner: player)
    }
}
