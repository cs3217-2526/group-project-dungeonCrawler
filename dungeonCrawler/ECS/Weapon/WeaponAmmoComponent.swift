//
//  WeaponAmmoComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/4/26.
//

import Foundation

/// Attached to weapon entities that use a magazine/reload system (firearms).
/// Weapons without this component (spellbooks, melee) are unaffected.
public class WeaponAmmoComponent: Component {
    /// Bullets currently in the magazine.
    var currentAmmo: Int
    /// Maximum bullets per magazine.
    let magazineSize: Int
    /// How long a full reload takes, in seconds.
    let reloadTime: Float
    /// Whether a reload is currently in progress.
    var isReloading: Bool
    /// Accumulated time since reload began.
    var reloadElapsed: Float

    public init(magazineSize: Int, reloadTime: Float) {
        self.magazineSize = magazineSize
        self.currentAmmo = magazineSize
        self.reloadTime = reloadTime
        self.isReloading = false
        self.reloadElapsed = 0
    }

    /// Convenience: fraction of reload progress in [0, 1].
    var reloadProgress: Float {
        guard isReloading, reloadTime > 0 else { return 0 }
        return min(reloadElapsed / reloadTime, 1)
    }
}
