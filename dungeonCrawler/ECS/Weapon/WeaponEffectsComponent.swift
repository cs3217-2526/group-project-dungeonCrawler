//
//  WeaponEffectComponent.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation

public class WeaponEffectsComponent: Component {
    var effects: [any WeaponEffect]
    
    public init(effects: [any WeaponEffect] = []) {
        self.effects = effects
    }
}
