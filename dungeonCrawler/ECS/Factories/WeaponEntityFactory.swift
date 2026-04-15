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
    }

    /// Components include:
    /// Transform Component
    /// Facing Component
    /// Owner Component
    /// Weapon Timing Component
    /// Weapon Effects Component
    /// Weapon Render Component
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
                offset: offset
            ),
            to: entity)
        world.addComponent(component: WeaponEffectsComponent(effects: effects), to: entity)

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
