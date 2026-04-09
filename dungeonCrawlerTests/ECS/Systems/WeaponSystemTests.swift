import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class WeaponSystemTests: XCTestCase {

    var world: World!
    var system: WeaponSystem!

    // MARK: - Owner entity + default components
    var ownerEntity: Entity!
    var ownerTransform: TransformComponent!        // position: (0, 0),   velocity: (1, 0), facing: right  [default]
    var ownerVelocity: VelocityComponent!
    var ownerInput: InputComponent!               // isShooting: true,   aimDirection: (1, 0)              [default]
    var ownerFacing: FacingComponent!

    // Owner component variants
    var ownerTransformAt100_50: TransformComponent!   // position: (100, 50) — facing-right position tests
    var ownerTransformAt50_30: TransformComponent!    // position: (50, 30)  — projectile spawn position test
    var ownerVelocityFacingLeft: VelocityComponent!   // linear: (-1, 0)
    var ownerVelocityZero: VelocityComponent!         // linear: (0, 0)
    var ownerFacingLeft: FacingComponent!
    var ownerInputNotShooting: InputComponent!        // isShooting: false
    var ownerInputAimLeft: InputComponent!            // isShooting: true, aimDirection: (-1, 0)

    // MARK: - Weapon entity + default components
    var weaponEntity: Entity!
    var weaponTransform: TransformComponent!       // position: (10, -5)  [default offset from origin]
    var weaponVelocity: VelocityComponent!
    var weaponOwner: OwnerComponent!              // offset: (10, -5)    [default]
    var weaponFacing: FacingComponent!
    var weaponTiming: WeaponTimingComponent!       // coolDown: 0.5       [default]
    var weaponEffects: WeaponEffectsComponent!     // manaCost: 0, damage: 25 [default]

    // Weapon component variants
    var weaponTransformAt110_45: TransformComponent!  // position: (110, 45) — facing-right from (100,50) + offset (10,-5)
    var weaponTransformAt90_45: TransformComponent!   // position: (90, 45)  — facing-left  from (100,50) + offset (10,-5)
    var weaponTransformAt50_30: TransformComponent!   // position: (50, 30)  — zero-offset from owner at (50,30)
    var weaponOwnerOffset10_Neg5: OwnerComponent!     // offset: (10, -5)    — explicit for position tests
    var weaponOwnerOffset10_0: OwnerComponent!        // offset: (10,  0)    — tracks-owner test
    var weaponOwnerOffsetZero: OwnerComponent!        // offset: (0,   0)    — projectile spawn position test
    var weaponFacingLeft: FacingComponent!
    var weaponTimingLongCooldown: WeaponTimingComponent!  // coolDown: 1.0

    // WeaponEffects variants — named by (manaCost, damage)
    var weaponEffectsManaCost20_Damage25: WeaponEffectsComponent!
    var weaponEffectsManaCost20_Damage25b: WeaponEffectsComponent! // second independent instance for blocked-mana tests
    var weaponEffectsManaCost10_Damage25: WeaponEffectsComponent!
    var weaponEffectsManaCost15_Damage25: WeaponEffectsComponent!
    var weaponEffectsManaCost99_Damage25: WeaponEffectsComponent!
    var weaponEffectsManaCost18_Damage25: WeaponEffectsComponent!
    var weaponEffectsManaCost0_Damage42: WeaponEffectsComponent!

    // ManaComponent variants — named by (current, max)
    var mana10of100: ManaComponent!    // current: 10,  max: 100
    var mana20of100: ManaComponent!    // current: 20,  max: 100
    var mana50of100: ManaComponent!    // current: 50,  max: 100
    var mana100of100: ManaComponent!   // current: 100, max: 100

    // MARK: - Static defaults
    static let defaultOwnerPosition: SIMD2<Float>   = .zero
    static let defaultOwnerVelocity: SIMD2<Float>   = SIMD2(1, 0)
    static let defaultOffset: SIMD2<Float>           = SIMD2(10, -5)
    static let defaultAimDirection: SIMD2<Float>     = SIMD2(1, 0)
    static let defaultCoolDownInterval: TimeInterval = 0.5
    static let defaultProjectileDamage: Float        = 25
    static let defaultProjectileSpeed: Float         = 300
    static let defaultProjectileRange: Float         = 400

    override func setUp() {
        super.setUp()
        world  = World()
        system = WeaponSystem()

        // MARK: Owner defaults
        ownerTransform    = TransformComponent(position: Self.defaultOwnerPosition)
        ownerVelocity     = VelocityComponent(linear: Self.defaultOwnerVelocity)
        ownerInput        = InputComponent(moveDirection: .zero, aimDirection: Self.defaultAimDirection, isShooting: true)
        ownerFacing       = FacingComponent(facing: .right)

        // MARK: Owner variants
        ownerTransformAt100_50    = TransformComponent(position: SIMD2(100, 50))
        ownerTransformAt50_30     = TransformComponent(position: SIMD2(50, 30))
        ownerVelocityFacingLeft   = VelocityComponent(linear: SIMD2(-1, 0))
        ownerVelocityZero         = VelocityComponent(linear: .zero)
        ownerFacingLeft           = FacingComponent(facing: .left)
        ownerInputNotShooting     = InputComponent(moveDirection: .zero, aimDirection: Self.defaultAimDirection, isShooting: false)
        ownerInputAimLeft         = InputComponent(moveDirection: .zero, aimDirection: SIMD2(-1, 0), isShooting: true)

        ownerEntity = world.createEntity()
        world.addComponent(component: ownerTransform, to: ownerEntity)
        world.addComponent(component: ownerVelocity,  to: ownerEntity)
        world.addComponent(component: ownerInput,     to: ownerEntity)
        world.addComponent(component: ownerFacing,    to: ownerEntity)

        // MARK: Weapon defaults
        weaponTransform = TransformComponent(position: Self.defaultOwnerPosition + Self.defaultOffset)
        weaponVelocity  = VelocityComponent()
        weaponOwner     = OwnerComponent(ownerEntity: ownerEntity, offset: Self.defaultOffset)
        weaponFacing    = FacingComponent(facing: .right)
        weaponTiming    = WeaponTimingComponent(lastFiredAt: 0, coolDownInterval: Self.defaultCoolDownInterval, attackSpeed: 1)
        weaponEffects   = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 0),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])

        // MARK: Weapon transform variants
        weaponTransformAt110_45 = TransformComponent(position: SIMD2(110, 45))
        weaponTransformAt90_45  = TransformComponent(position: SIMD2(90, 45))
        weaponTransformAt50_30  = TransformComponent(position: SIMD2(50, 30))

        // MARK: Weapon owner variants
        weaponOwnerOffset10_Neg5 = OwnerComponent(ownerEntity: ownerEntity, offset: SIMD2(10, -5))
        weaponOwnerOffset10_0    = OwnerComponent(ownerEntity: ownerEntity, offset: SIMD2(10,  0))
        weaponOwnerOffsetZero    = OwnerComponent(ownerEntity: ownerEntity, offset: .zero)

        // MARK: Weapon facing variant
        weaponFacingLeft = FacingComponent(facing: .left)

        // MARK: Weapon timing variant
        weaponTimingLongCooldown = WeaponTimingComponent(lastFiredAt: 0, coolDownInterval: 1.0, attackSpeed: 1)

        // MARK: Weapon effects variants
        weaponEffectsManaCost20_Damage25 = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 20),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])
        weaponEffectsManaCost20_Damage25b = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 20),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])
        weaponEffectsManaCost10_Damage25 = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 10),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])
        weaponEffectsManaCost15_Damage25 = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 15),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])
        weaponEffectsManaCost99_Damage25 = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 99),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])
        weaponEffectsManaCost18_Damage25 = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 18),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: Self.defaultProjectileDamage, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])
        weaponEffectsManaCost0_Damage42 = WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: 0),
            SpawnProjectileEffect(speed: Self.defaultProjectileSpeed, effectiveRange: Self.defaultProjectileRange, damage: 42, spriteName: "normalHandgunBullet", collisionSize: SIMD2<Float>(6, 6))
        ])

        // MARK: Mana variants
        mana10of100  = { var m = ManaComponent(base: 10,  max: 100, regenRate: 0); m.value.current = 10;  return m }()
        mana20of100  = { var m = ManaComponent(base: 20,  max: 100, regenRate: 0); m.value.current = 20;  return m }()
        mana50of100  = { var m = ManaComponent(base: 50,  max: 100, regenRate: 0); m.value.current = 50;  return m }()
        mana100of100 = { var m = ManaComponent(base: 100, max: 100, regenRate: 0); m.value.current = 100; return m }()

        weaponEntity = world.createEntity()
        world.addComponent(component: weaponTransform, to: weaponEntity)
        world.addComponent(component: weaponVelocity,  to: weaponEntity)
        world.addComponent(component: weaponOwner,     to: weaponEntity)
        world.addComponent(component: weaponFacing,    to: weaponEntity)
        world.addComponent(component: weaponTiming,    to: weaponEntity)
        world.addComponent(component: weaponEffects,   to: weaponEntity)
    }

    override func tearDown() {
        ownerEntity               = nil
        ownerTransform            = nil
        ownerVelocity             = nil
        ownerInput                = nil
        ownerFacing               = nil
        ownerTransformAt100_50    = nil
        ownerTransformAt50_30     = nil
        ownerVelocityFacingLeft   = nil
        ownerVelocityZero         = nil
        ownerFacingLeft           = nil
        ownerInputNotShooting     = nil
        ownerInputAimLeft         = nil
        weaponEntity              = nil
        weaponTransform           = nil
        weaponVelocity            = nil
        weaponOwner               = nil
        weaponFacing              = nil
        weaponTiming              = nil
        weaponEffects             = nil
        weaponTransformAt110_45   = nil
        weaponTransformAt90_45    = nil
        weaponTransformAt50_30    = nil
        weaponOwnerOffset10_Neg5  = nil
        weaponOwnerOffset10_0     = nil
        weaponOwnerOffsetZero     = nil
        weaponFacingLeft          = nil
        weaponTimingLongCooldown  = nil
        weaponEffectsManaCost20_Damage25  = nil
        weaponEffectsManaCost20_Damage25b = nil
        weaponEffectsManaCost10_Damage25  = nil
        weaponEffectsManaCost15_Damage25  = nil
        weaponEffectsManaCost99_Damage25  = nil
        weaponEffectsManaCost18_Damage25  = nil
        weaponEffectsManaCost0_Damage42   = nil
        mana10of100               = nil
        mana20of100               = nil
        mana50of100               = nil
        mana100of100              = nil
        system                    = nil
        world                     = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func getSpawnedProjectiles() -> [Entity] {
        world.entities(with: ProjectileComponent.self)
    }

    // MARK: - Position and mirror offset

    func testWeaponPositionFollowsOwnerFacingRight() {
        world.addComponent(component: ownerTransformAt100_50,   to: ownerEntity)
        world.addComponent(component: weaponTransformAt110_45,  to: weaponEntity)
        world.addComponent(component: weaponOwnerOffset10_Neg5, to: weaponEntity)

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: weaponEntity)!
        XCTAssertEqual(transform.position.x, 110, accuracy: 0.01)
        XCTAssertEqual(transform.position.y,  45, accuracy: 0.01)
    }

    func testWeaponOffsetXMirroredWhenFacingLeft() {
        world.addComponent(component: ownerTransformAt100_50,   to: ownerEntity)
        world.addComponent(component: ownerVelocityFacingLeft,  to: ownerEntity)
        world.addComponent(component: ownerFacingLeft,          to: ownerEntity)
        world.addComponent(component: weaponTransformAt90_45,   to: weaponEntity)
        world.addComponent(component: weaponOwnerOffset10_Neg5, to: weaponEntity)
        world.addComponent(component: weaponFacingLeft,         to: weaponEntity)

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: weaponEntity)!
        XCTAssertEqual(transform.position.x, 90, accuracy: 0.01)
        XCTAssertEqual(transform.position.y, 45, accuracy: 0.01)
    }

    func testWeaponYOffsetUnchangedWhenFacingRight() {
        // Default setUp: position (0,0), facing right, offset (10,-5) — no overrides needed
        system.update(deltaTime: 0.1, world: world)

        let y = world.getComponent(type: TransformComponent.self, for: weaponEntity)!.position.y
        XCTAssertEqual(y, -5, accuracy: 0.01)
    }

    func testWeaponYOffsetUnchangedWhenFacingLeft() {
        world.addComponent(component: ownerVelocityFacingLeft, to: ownerEntity)
        world.addComponent(component: ownerFacingLeft,         to: ownerEntity)
        world.addComponent(component: weaponFacingLeft,        to: weaponEntity)

        system.update(deltaTime: 0.1, world: world)

        let y = world.getComponent(type: TransformComponent.self, for: weaponEntity)!.position.y
        XCTAssertEqual(y, -5, accuracy: 0.01)
    }

    func testWeaponDefaultsFacingRightWhenVelocityIsZero() {
        world.addComponent(component: ownerVelocityZero, to: ownerEntity)

        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: weaponEntity)!
        XCTAssertEqual(transform.position.x, 10, accuracy: 0.01)
        XCTAssertEqual(transform.position.y, -5, accuracy: 0.01)
    }

    func testWeaponTracksOwnerAfterOwnerMoves() {
        world.addComponent(component: weaponOwnerOffset10_0, to: weaponEntity)

        system.update(deltaTime: 0.1, world: world)
        world.getComponent(type: TransformComponent.self, for: ownerEntity)?.position = SIMD2(50, 0)
        system.update(deltaTime: 0.1, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: weaponEntity)!
        XCTAssertEqual(transform.position.x, 60, accuracy: 0.01)
    }

    // MARK: - Cooldown

    func testWeaponDoesNotFireBeforeCooldownElapses() {
        world.addComponent(component: weaponTimingLongCooldown, to: weaponEntity)

        system.update(deltaTime: 0.5, world: world)

        XCTAssertTrue(getSpawnedProjectiles().isEmpty)
    }

    func testWeaponFiresWhenCooldownElapsed() {
        // Default setUp: isShooting true, coolDownInterval 0.5 — no overrides needed
        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testWeaponUpdatesLastFiredAtAfterFiring() {
        // Default setUp: isShooting true, coolDownInterval 0.5 — no overrides needed
        system.update(deltaTime: 1.0, world: world)

        let timing = world.getComponent(type: WeaponTimingComponent.self, for: weaponEntity)!
        XCTAssertEqual(timing.lastFiredAt, 1.0, accuracy: 0.001)
    }

    func testWeaponDoesNotFireAgainWithinCooldown() {
        world.addComponent(component: weaponTimingLongCooldown, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 0.5, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testWeaponFiresAgainAfterCooldownResets() {
        world.addComponent(component: weaponTimingLongCooldown, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 2)
    }

    func testWeaponDoesNotFireWhenNotShooting() {
        world.addComponent(component: ownerInputNotShooting, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertTrue(getSpawnedProjectiles().isEmpty)
    }

    // MARK: - Mana gate

    func testWeaponBlockedWhenInsufficientMana() {
        world.addComponent(component: weaponEffectsManaCost20_Damage25, to: weaponEntity)
        world.addComponent(component: mana10of100, to: ownerEntity) // only 10, need 20

        system.update(deltaTime: 1.0, world: world)

        XCTAssertTrue(getSpawnedProjectiles().isEmpty)
    }

    func testWeaponFiresWhenManaExactlyEqualsToCost() {
        world.addComponent(component: weaponEffectsManaCost20_Damage25b, to: weaponEntity)
        world.addComponent(component: mana20of100, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testWeaponFiresWhenManaSufficient() {
        world.addComponent(component: weaponEffectsManaCost10_Damage25, to: weaponEntity)
        world.addComponent(component: mana50of100, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testManaDeductedAfterFiring() {
        world.addComponent(component: weaponEffectsManaCost15_Damage25, to: weaponEntity)
        world.addComponent(component: mana50of100, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: ownerEntity)!
        XCTAssertEqual(mana.value.current, 35, accuracy: 0.001)
    }

    func testManaNotDeductedWhenShotBlocked() {
        world.addComponent(component: weaponEffectsManaCost20_Damage25, to: weaponEntity)
        world.addComponent(component: mana10of100, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: ownerEntity)!
        XCTAssertEqual(mana.value.current, 10, accuracy: 0.001)
    }

    func testOwnerWithoutManaComponentFiresFreely() {
        // No ManaComponent added — gate should not apply
        world.addComponent(component: weaponEffectsManaCost99_Damage25, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testManaClampsToZeroNotNegative() {
        world.addComponent(component: weaponEffectsManaCost10_Damage25, to: weaponEntity)
        world.addComponent(component: mana10of100, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world) // fires, mana 10 → 0
        system.update(deltaTime: 1.0, world: world) // blocked (0 < 10), mana stays 0

        let mana = world.getComponent(type: ManaComponent.self, for: ownerEntity)!
        XCTAssertEqual(mana.value.current, 0, accuracy: 0.001)
        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    // MARK: - Projectile carries correct values

    func testSpawnedProjectileHasDamageFromWeapon() {
        world.addComponent(component: weaponEffectsManaCost0_Damage42, to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let contactDamage = world.getComponent(type: ContactDamageComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertEqual(contactDamage.damage, 42, accuracy: 0.001)
    }

    func testManaConsumedUsingWeaponEffectCost() {
        world.addComponent(component: weaponEffectsManaCost18_Damage25, to: weaponEntity)
        world.addComponent(component: mana100of100, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: ownerEntity)!
        XCTAssertEqual(mana.value.current, 82, accuracy: 0.001)
    }

    // MARK: - Projectile basic checks

    func testSpawnedProjectileHasTransformAtOwnerPosition() {
        world.addComponent(component: ownerTransformAt50_30,  to: ownerEntity)
        world.addComponent(component: weaponTransformAt50_30, to: weaponEntity)
        world.addComponent(component: weaponOwnerOffsetZero,  to: weaponEntity)

        system.update(deltaTime: 1.0, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertEqual(transform.position.x, 50, accuracy: 0.01)
        XCTAssertEqual(transform.position.y, 30, accuracy: 0.01)
    }

    func testSpawnedProjectileHasVelocityAlignedWithAimDirection() {
        // Default setUp: aimDirection (1, 0) — no overrides needed
        system.update(deltaTime: 1.0, world: world)

        let velocity = world.getComponent(type: VelocityComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertGreaterThan(velocity.linear.x, 0)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.01)
    }

    func testSpawnedProjectileVelocityReflectsAimDirection() {
        world.addComponent(component: ownerInputAimLeft, to: ownerEntity)

        system.update(deltaTime: 1.0, world: world)

        let velocity = world.getComponent(type: VelocityComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertLessThan(velocity.linear.x, 0)
    }

    func testSpawnedProjectileHasSpriteComponent() {
        // Default setUp — no overrides needed
        system.update(deltaTime: 1.0, world: world)

        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: getSpawnedProjectiles()[0]))
    }

    func testSpawnedProjectileOwnerMatchesPlayerEntity() {
        // Default setUp — no overrides needed
        system.update(deltaTime: 1.0, world: world)

        let projectileOwner = world.getComponent(type: OwnerComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertEqual(projectileOwner.ownerEntity, ownerEntity)
    }

    func testSpawnedProjectileHasPositiveEffectiveRange() {
        // Default setUp — no overrides needed
        system.update(deltaTime: 1.0, world: world)

        let range = world.getComponent(type: EffectiveRangeComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertGreaterThan(range.value.current, 0)
    }
}
