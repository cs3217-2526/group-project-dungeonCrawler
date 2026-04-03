//
//  WeaponEntityFactory.swift
//  dungeonCrawler
//
//

import Foundation
import simd

public struct WeaponEntityFactory: EntityFactory {
    let player: Entity
    let textureName: String
    let offset: SIMD2<Float>
    let scale: Float
    let lastFiredAt: Float
    let coolDownIntervel: TimeInterval?
    let attackSpeed: Float?
    let effects: [any WeaponEffect]
    let anchorPoint: SIMD2<Float>
    let initRotation: Float

    public init(
        player: Entity,
        textureName: String,
        offset: SIMD2<Float> = .zero,
        scale: Float = 1,
        lastFiredAt: Float = 0,
        coolDownIntervel: TimeInterval?,
        attackSpeed: Float?,
        effects: [any WeaponEffect],
        anchorPoint: SIMD2<Float>?,
        initRotation: Float?
    ) {
        self.player = player
        self.textureName = textureName
        self.offset = offset
        self.scale = scale
        self.lastFiredAt = lastFiredAt
        self.coolDownIntervel = coolDownIntervel
        self.attackSpeed = attackSpeed
        self.effects = effects
        self.anchorPoint = anchorPoint ?? SIMD2<Float>(0.5, 0.5)
        self.initRotation = initRotation ?? 0
    }

    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()
        let startPos = world.getComponent(type: TransformComponent.self, for: player)?.position ?? .zero
        let ownerFacing = world.getComponent(type: FacingComponent.self, for: player)?.facing ?? .right

        world.addComponent(
            component: TransformComponent(
                position: startPos + offset,
                rotation: initRotation,
                scale: scale),
            to: entity
        )
        world.addComponent(component: FacingComponent(facing: ownerFacing), to: entity)
        world.addComponent(component: OwnerComponent(ownerEntity: player, offset: offset), to: entity)
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
                initRotation: initRotation
            ),
            to: entity
        )
        world.addComponent(component: WeaponEffectsComponent(effects: effects), to: entity)

        return entity
    }
}
