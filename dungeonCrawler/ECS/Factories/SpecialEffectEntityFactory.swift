//
//  SpecialEffectEntityFactory.swift
//  dungeonCrawler
//
//  Created by Letian on 11/4/26.
//

import Foundation
import simd

public struct SpecialEffectZoneEntityFactory: EntityFactory {
    let textureName: String
    let radius: Float
    let damagePerSecond: Float
    let duration: Float
    let elapsed: Float
    let position: SIMD2<Float>

    @discardableResult
    public func make(in world: World) -> Entity {
        let fireZone = world.createEntity()
        world.addComponent(component: FireZoneComponent(radius: radius, damagePerSecond: damagePerSecond, duration: duration, elapsed: elapsed), to: fireZone)
        world.addComponent(component: SpriteComponent(content: .texture(name: textureName), layer: .zone), to: fireZone)
        world.addComponent(component: TransformComponent(position: position), to: fireZone)
        return fireZone
    }
}
