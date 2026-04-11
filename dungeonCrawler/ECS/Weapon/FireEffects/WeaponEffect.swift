//
//  WeaponEffect.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation

public protocol WeaponEffect {
    func apply(context: FireContext) -> FireEffectResult
}
