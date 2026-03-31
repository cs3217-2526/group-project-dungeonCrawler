//
//  ConsumeManaEffect.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation

struct ConsumeManaEffect: WeaponEffect {
    let amount: Float

    func apply(context: FireContext) -> FireEffectResult {
        guard let mana = context.world.getComponent(type: ManaComponent.self, for: context.owner) else {
            return .success
        }
        guard mana.value.current >= amount else {
            return .blocked("insufficient_mana")
        }
        context.world.modifyComponent(type: ManaComponent.self, for: context.owner) { mana in
            mana.value.current -= amount
            mana.value.clampToMin()
        }
        return .success
    }
}
