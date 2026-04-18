//
//  ConsumeAmmoEffect.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/4/26.
//

import Foundation

/// Attached to firearm weapons.
/// Blocks firing when the magazine is empty or reloading.
/// Decrements ammo on a successful shot and auto-triggers reload on empty.
struct ConsumeAmmoEffect: WeaponEffect {
    func apply(context: FireContext) -> FireEffectResult {
        guard let ammo = context.world.getComponent(type: WeaponAmmoComponent.self, for: context.weapon) else {
            // No ammo component means unlimited — let it through.
            return .success
        }

        guard !ammo.isReloading else {
            return .blocked("reloading")
        }

        guard ammo.currentAmmo > 0 else {
            // Trigger auto-reload and block this shot.
            ammo.isReloading = true
            ammo.reloadElapsed = 0
            return .blocked("empty_magazine")
        }

        ammo.currentAmmo -= 1

        // Auto-reload the moment the last bullet leaves the chamber.
        if ammo.currentAmmo == 0 {
            ammo.isReloading = true
            ammo.reloadElapsed = 0
        }

        return .success
    }
}
