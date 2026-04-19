import XCTest
import simd
@testable import dungeonCrawler

// MARK: - Mocks

final class MockHUDBackend: HUDBackend {
    struct AmmoCall {
        let current: Int
        let max: Int
        let isReloading: Bool
        let reloadProgress: Float
    }

    var healthUpdates: [(current: Float, max: Float)] = []
    var manaUpdates:   [(current: Float, max: Float)] = []
    var ammoCalls:     [AmmoCall]                      = []
    var hideAmmoCount: Int                             = 0

    func updateHealthBar(current: Float, max: Float) { healthUpdates.append((current, max)) }
    func updateManaBar(current: Float, max: Float)   { manaUpdates.append((current, max)) }
    func updateAmmoBar(current: Int, max: Int, isReloading: Bool, reloadProgress: Float) {
        ammoCalls.append(AmmoCall(current: current, max: max,
                                  isReloading: isReloading, reloadProgress: reloadProgress))
    }
    func hideAmmoBar() { hideAmmoCount += 1 }
    func updateChargeBar(progress: Float) {}
    func hideChargeBar() {}
}

// MARK: - Tests

@MainActor
final class HUDSystemTests: XCTestCase {

    var world:   World!
    var backend: MockHUDBackend!
    var system:  HUDSystem!
    var queues:  CommandQueues!

    // MARK: - Entities

    var playerEntity:       Entity!
    var firearmWeaponEntity: Entity!
    var meleeWeaponEntity:   Entity!

    // MARK: - Component variants

    var playerTag:     PlayerTagComponent!
    var health60of100: HealthComponent!
    var health80:      HealthComponent!    // base 80, no explicit max
    var mana40of100:   ManaComponent!

    var ammoFull:      WeaponAmmoComponent!   // 6/6, not reloading
    var ammoPartial:   WeaponAmmoComponent!   // 3/6, not reloading
    var ammoReloading: WeaponAmmoComponent!   // 6/6, isReloading=true, elapsed=1.0 of 2.0

    var equippedFirearm: EquippedWeaponComponent!
    var equippedMelee:   EquippedWeaponComponent!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        world   = World()
        backend = MockHUDBackend()
        queues  = CommandQueues()
        system  = HUDSystem(backend: backend, commandQueues: queues)

        playerTag     = PlayerTagComponent()
        health60of100 = HealthComponent(base: 60, max: 100)
        health80      = HealthComponent(base: 80)
        mana40of100   = ManaComponent(base: 40, max: 100, regenRate: 0)

        ammoFull      = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)

        ammoPartial   = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)
        ammoPartial.currentAmmo = 3

        ammoReloading = WeaponAmmoComponent(magazineSize: 6, reloadTime: 2.0)
        ammoReloading.isReloading   = true
        ammoReloading.reloadElapsed = 1.0

        firearmWeaponEntity = world.createEntity()
        world.addComponent(component: ammoFull, to: firearmWeaponEntity)

        meleeWeaponEntity = world.createEntity()

        playerEntity = world.createEntity()
        // No playerTag / health / mana / weapon attached by default — each test opts in

        equippedFirearm = EquippedWeaponComponent(primaryWeapon: firearmWeaponEntity)
        equippedMelee   = EquippedWeaponComponent(primaryWeapon: meleeWeaponEntity)
    }

    override func tearDown() {
        world               = nil
        backend             = nil
        queues              = nil
        system              = nil
        playerEntity        = nil
        firearmWeaponEntity = nil
        meleeWeaponEntity   = nil
        playerTag           = nil
        health60of100       = nil
        health80            = nil
        mana40of100         = nil
        ammoFull            = nil
        ammoPartial         = nil
        ammoReloading       = nil
        equippedFirearm     = nil
        equippedMelee       = nil
        super.tearDown()
    }

    // MARK: - No player

    func testNoPlayerEntityProducesNoCalls() {
        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.healthUpdates.isEmpty)
        XCTAssertTrue(backend.manaUpdates.isEmpty)
        XCTAssertTrue(backend.ammoCalls.isEmpty)
    }

    // MARK: - Health bar

    func testHealthBarUpdatedWithCorrectValues() {
        world.addComponent(component: playerTag,     to: playerEntity)
        world.addComponent(component: health60of100, to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(backend.healthUpdates.count, 1)
        XCTAssertEqual(backend.healthUpdates[0].current, 60,  accuracy: 0.001)
        XCTAssertEqual(backend.healthUpdates[0].max,     100, accuracy: 0.001)
    }

    func testHealthBarUsesBaseAsMaxWhenMaxIsNil() {
        world.addComponent(component: playerTag, to: playerEntity)
        world.addComponent(component: health80,  to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(backend.healthUpdates[0].max, 80, accuracy: 0.001)
    }

    func testNoHealthComponentProducesNoHealthUpdate() {
        world.addComponent(component: playerTag, to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.healthUpdates.isEmpty)
    }

    // MARK: - Mana bar

    func testManaBarUpdatedWithCorrectValues() {
        world.addComponent(component: playerTag,    to: playerEntity)
        world.addComponent(component: mana40of100,  to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(backend.manaUpdates.count, 1)
        XCTAssertEqual(backend.manaUpdates[0].current, 40,  accuracy: 0.001)
        XCTAssertEqual(backend.manaUpdates[0].max,     100, accuracy: 0.001)
    }

    func testNoManaComponentProducesNoManaUpdate() {
        world.addComponent(component: playerTag, to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.manaUpdates.isEmpty)
    }

    // MARK: - Ammo bar

    func testFirearmPrimaryWeaponShowsAmmoBar() {
        world.addComponent(component: playerTag,      to: playerEntity)
        world.addComponent(component: equippedFirearm, to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertFalse(backend.ammoCalls.isEmpty)
        XCTAssertEqual(backend.hideAmmoCount, 0)
    }

    func testAmmoBarReflectsCurrentAndMaxAmmo() {
        world.addComponent(component: playerTag,      to: playerEntity)
        world.addComponent(component: equippedFirearm, to: playerEntity)
        world.addComponent(component: ammoPartial,    to: firearmWeaponEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(backend.ammoCalls[0].current, 3)
        XCTAssertEqual(backend.ammoCalls[0].max,     6)
    }

    func testAmmoBarReflectsReloadingState() {
        world.addComponent(component: playerTag,      to: playerEntity)
        world.addComponent(component: equippedFirearm, to: playerEntity)
        world.addComponent(component: ammoReloading,  to: firearmWeaponEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.ammoCalls[0].isReloading)
        XCTAssertEqual(backend.ammoCalls[0].reloadProgress, 0.5, accuracy: 0.001)
    }

    func testMeleePrimaryWeaponHidesAmmoBar() {
        world.addComponent(component: playerTag,    to: playerEntity)
        world.addComponent(component: equippedMelee, to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.ammoCalls.isEmpty)
        XCTAssertEqual(backend.hideAmmoCount, 1)
    }

    func testNoEquippedWeaponHidesAmmoBar() {
        world.addComponent(component: playerTag, to: playerEntity)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertEqual(backend.hideAmmoCount, 1)
    }
}
