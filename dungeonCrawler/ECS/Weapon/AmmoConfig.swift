//
//  AmmoConfig.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/4/26.
//

import Foundation

/// Describes the magazine and reload behaviour for a firearm weapon.
/// Attach via `WeaponBase.ammoConfig` in WeaponLibrary.
/// Weapons without this (spellbooks, melee) have no ammo system.
public struct AmmoConfig {
    /// Number of shots per magazine.
    let magazineSize: Int
    /// Seconds to fully reload.
    let reloadTime: Float
}
