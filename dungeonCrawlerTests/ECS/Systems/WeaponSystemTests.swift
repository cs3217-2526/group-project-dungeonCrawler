//
//  WeaponAmmoSystemTests.swift
//  dungeonCrawlerTests
//
//  Tests for ConsumeAmmoEffect, WeaponAmmoComponent, and the WeaponSystem
//  reload tick. Mirrors the style and setUp/tearDown pattern of WeaponSystemTests.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class WeaponAmmoSystemTests: XCTestCase {

    var world:  World!
    var system: WeaponSystem!

    // MARK: - Owner

    var ownerEntity:    Entity!
    var ownerTransform: TransformComponent!
    var ownerInput:     InputComponent!     // isShooting: true, aimDirection: (1, 0)
    var ownerFacing:    FacingComponent!

    var ownerInputNotShooting: InputComponent!

    // MARK: - Weapon

    var weaponEntity:  Entity!
    var weaponOwner:   OwnerComponent!
    var weaponFacing:  FacingComponent!
    var weaponRender:  WeaponRenderComponent!
    var weaponTiming:  WeaponTimingComponent!  // coolDown: 0.5

    // MARK: - Ammo component variants

    /// Standard 6-round magazine, 2 s reload.
    var ammo6of6:  WeaponAmmoComponent!
    /// Already partially spent: 2 rounds left, 6-round mag.
    var ammo2of6:  WeaponAmmoComponent!
    /// Single-shot magazine (e.g. sniper), 2.5 s reload.
    var ammo1of1:  WeaponAmmoComponent!
    /// Empty magazine, not yet reloading.
    var ammo0of6:  WeaponAmmoComponent!
    /// Mid-reload state: 1 s elapsed of a 2 s reload.
    var ammoReloading: WeaponAmmoComponent!

    // MARK: - Effects variants

    /// Firearm: ConsumeAmmoEffect + projectile spawn — no mana cost.
    var firearmsEffects: WeaponEffectsComponent!
    /// Magical: ConsumeManaEffect + projectile spawn.
    var magicalEffects:  WeaponEffectsComponent!
    var drainedMana: ManaComponent!

    // MARK: - Static defaults

    static let defaultOffset:    SIMD2<Float>   = SIMD2(10, -5)
    static let defaultAim:       SIMD2<Float>   = SIMD2(1, 0)
    static let defaultCooldown:  TimeInterval   = 0.5

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        world  = World()
        system = WeaponSystem()

        // Owner
        ownerTransform      = TransformComponent(position: .zero)
        ownerInput          = InputComponent(moveDirection: .zero, aimDirection: Self.defaultAim, isShooting: true)
        ownerFacing         = FacingComponent(facing: .right)
        ownerInputNotShooting = InputComponent(moveDirection: .zero, aimDirection: Self.defaultAim, isShooting: false)

        ownerEntity = world.createEntity()
        world.addComponent(component: ownerTransform,  to: ownerEntity)
        world.addComponent(component: ownerInput,      to: ownerEntity)
        world.addComponent(component: ownerFacing,     to: ownerEntity)
        
        // Weapon
        weaponOwner   = OwnerComponent(ownerEntity: ownerEntity)
        weaponFacing  = FacingComponent(facing: .right)
        weaponRender  = WeaponRenderComponent(
            textureName: "handgun",
            anchorPoint: SIMD2(0.5, 0.5),
            initRotation: 0,
            offset: Self.defaultOffset
        )
        weaponTiming  = WeaponTimingComponent(
            lastFiredAt: 0,
            coolDownInterval: Self.defaultCooldown,
            attackSpeed: 1
        )
        firearmsEffects = WeaponEffectsComponent(effects: [
            ConsumeAmmoEffect(),
            SpawnProjectileEffect(
                speed: 300, effectiveRange: 400, damage: 15,
                spriteName: "normalHandgunBullet",
                collisionSize: SIMD2<Float>(6, 6), hitEffects: []
            )
        ])
        magicalEffects = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 5),
            SpawnProjectileEffect(
                speed: 250, effectiveRange: 500, damage: 30,
                spriteName: "magicOrb",
                collisionSize: SIMD2<Float>(8, 8), hitEffects: []
            )
        ])

        // Ammo variants
        ammo6of6 = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)

        ammo2of6 = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)
        ammo2of6.currentAmmo = 2

        ammo1of1 = WeaponAmmoComponent(magazineSize: 1, reloadTime: 2.5)

        ammo0of6 = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)
        ammo0of6.currentAmmo = 0

        ammoReloading = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)
        ammoReloading.currentAmmo = 0
        ammoReloading.isReloading = true
        ammoReloading.reloadElapsed = 1.0

        weaponEntity = world.createEntity()
        world.addComponent(component: TransformComponent(position: Self.defaultOffset), to: weaponEntity)
        world.addComponent(component: weaponOwner,   to: weaponEntity)
        world.addComponent(component: weaponFacing,  to: weaponEntity)
        world.addComponent(component: weaponRender,  to: weaponEntity)
        world.addComponent(component: weaponTiming,  to: weaponEntity)
        world.addComponent(component: firearmsEffects, to: weaponEntity)
        drainedMana = ManaComponent(base: 0, max: 100, regenRate: 0)
    }

    override func tearDown() {
        ownerEntity         = nil
        ownerTransform      = nil
        ownerInput          = nil
        ownerFacing         = nil
        ownerInputNotShooting = nil
        weaponEntity        = nil
        weaponOwner         = nil
        weaponFacing        = nil
        weaponRender        = nil
        weaponTiming        = nil
        firearmsEffects     = nil
        magicalEffects      = nil
        ammo6of6            = nil
        ammo2of6            = nil
        ammo1of1            = nil
        ammo0of6            = nil
        ammoReloading       = nil
        drainedMana         = nil
        system              = nil
        world               = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func spawnedProjectiles() -> [Entity] {
        world.entities(with: ProjectileComponent.self)
    }

    // MARK: - Firing with ammo

    func testFirearmFiresWhenAmmoAvailable() {
        world.addComponent(component: ammo6of6, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(spawnedProjectiles().count, 1)
    }

    func testFirearmDecrementsAmmoOnFire() {
        world.addComponent(component: ammo6of6, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertEqual(ammo.currentAmmo, 5)
    }

    func testFirearmBlockedWhenAmmoIsZero() {
        world.addComponent(component: ammo0of6, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertTrue(spawnedProjectiles().isEmpty)
    }

    func testFirearmBlockedWhileReloading() {
        world.addComponent(component: ammoReloading, to: weaponEntity)

        system.update(deltaTime: 0.5, world: world)

        XCTAssertTrue(spawnedProjectiles().isEmpty)
    }

    func testFirearmWithNoAmmoComponentFiresUnlimited() {
        // No WeaponAmmoComponent — should behave like an unlimited enemy weapon
        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(spawnedProjectiles().count, 2)
    }

    // MARK: - Auto-reload trigger

    func testLastShotTriggersAutoReload() {
        world.addComponent(component: ammo1of1, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world) // fires last bullet

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertTrue(ammo.isReloading)
    }

    func testLastShotLeavesAmmoAtZeroDuringReload() {
        world.addComponent(component: ammo1of1, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertEqual(ammo.currentAmmo, 0)
    }

    func testEmptyMagazineWithoutReloadingTriggersAutoReload() {
        // Simulates player pressing fire on an empty, idle magazine
        world.addComponent(component: ammo0of6, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertTrue(ammo.isReloading)
    }

    // MARK: - Reload tick

    func testReloadProgressAdvancesEachFrame() {
        world.addComponent(component: ammoReloading, to: weaponEntity) // elapsed: 1.0, reloadTime: 2.0

        system.update(deltaTime: 0.5, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertEqual(ammo.reloadElapsed, 1.5, accuracy: 0.001)
    }

    func testReloadCompletesAfterFullDuration() {
        world.addComponent(component: ammoReloading, to: weaponEntity) // elapsed: 1.0, reloadTime: 2.0

        system.update(deltaTime: 1.0, world: world) // 1.0 + 1.0 = 2.0 → complete

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertFalse(ammo.isReloading)
    }

    func testReloadRestoresFullMagazine() {
        world.addComponent(component: ownerInputNotShooting, to: ownerEntity)
        world.addComponent(component: ammoReloading, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertEqual(ammo.currentAmmo, ammo.magazineSize)
    }

    func testReloadElapsedResetToZeroOnCompletion() {
        world.addComponent(component: ammoReloading, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertEqual(ammo.reloadElapsed, 0, accuracy: 0.001)
    }

    func testReloadDoesNotCompleteEarly() {
        world.addComponent(component: ammoReloading, to: weaponEntity) // elapsed: 1.0, reloadTime: 2.0

        system.update(deltaTime: 0.9, world: world) // total 1.9 — not yet done

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertTrue(ammo.isReloading)
        XCTAssertEqual(ammo.currentAmmo, 0)
    }

    func testReloadTicksEvenWhenPlayerNotShooting() {
        world.addComponent(component: ownerInputNotShooting, to: ownerEntity)
        world.addComponent(component: ammoReloading, to: weaponEntity)

        system.update(deltaTime: 0.5, world: world)

        let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity)!
        XCTAssertEqual(ammo.reloadElapsed, 1.5, accuracy: 0.001)
    }

    func testCanFireAgainAfterReloadCompletes() {
        world.addComponent(component: ammo1of1, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)  // fires + triggers reload
        system.update(deltaTime: 3.0, world: world)  // reload completes (2.5 s), fires again

        XCTAssertEqual(spawnedProjectiles().count, 2)
    }

    // MARK: - Reload progress

    func testReloadProgressIsZeroWhenNotReloading() {
        world.addComponent(component: ammo6of6, to: weaponEntity)

        XCTAssertEqual(ammo6of6.reloadProgress, 0, accuracy: 0.001)
    }

    func testReloadProgressIsFiftyPercentMidReload() {
        // elapsed 1.0, reloadTime 2.0 → progress 0.5
        XCTAssertEqual(ammoReloading.reloadProgress, 0.5, accuracy: 0.001)
    }

    func testReloadProgressClampsToOne() {
        ammoReloading.reloadElapsed = 999
        XCTAssertEqual(ammoReloading.reloadProgress, 1.0, accuracy: 0.001)
    }

    // MARK: - Magical weapon (no ammo component)

    func testMagicalWeaponNotBlockedByAmmoSystem() {
        // Spellbook uses mana, no ammo component — should fire freely when mana allows
        world.addComponent(component: magicalEffects, to: weaponEntity)
        world.addComponent(component: ManaComponent(base: 100, max: 100, regenRate: 0), to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(spawnedProjectiles().count, 1)
    }

    func testMagicalWeaponBlockedByManaNotAmmo() {
        world.addComponent(component: magicalEffects, to: weaponEntity)
        // No ManaComponent at all — ConsumeManaEffect returns .success when component missing
        // Add a drained mana to verify block
        drainedMana.value.current = 0
        world.addComponent(component: drainedMana, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertTrue(spawnedProjectiles().isEmpty)
    }
}
