import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class WeaponSystemTests: XCTestCase {

    var world: World!
    var system: WeaponSystem!

    override func setUp() {
        super.setUp()
        world = World()
        system = WeaponSystem()
    }

    override func tearDown() {
        system = nil
        world = nil
        super.tearDown()
    }

    // MARK: - Helpers

    @discardableResult
    private func makeWeaponWithOwner(
        ownerPosition: SIMD2<Float> = .zero,
        ownerVelocity: SIMD2<Float> = .zero,
        offset: SIMD2<Float> = SIMD2(10, -5),
        isShooting: Bool = false,
        aimDirection: SIMD2<Float> = SIMD2(1, 0),
        coolDownInterval: TimeInterval = 1.0,
        lastFiredAt: Float = 0,
        projectileDamage: Float = 25,
        weaponManaCost: Float = 0,
        projectileSpeed: Float = 300,
        projectileEffectiveRange: Float = 400
    ) -> (owner: Entity, weapon: Entity) {
        let owner = world.createEntity()
        world.addComponent(component: TransformComponent(position: ownerPosition), to: owner)
        world.addComponent(component: VelocityComponent(linear: ownerVelocity), to: owner)
        world.addComponent(component: InputComponent(
            moveDirection: .zero,
            aimDirection: aimDirection,
            isShooting: isShooting
        ), to: owner)
        world.addComponent(component: FacingComponent(facing: ownerVelocity.x < 0 ? .left : .right), to: owner)

        let weapon = world.createEntity()
        world.addComponent(component: TransformComponent(position: ownerPosition + offset), to: weapon)
        world.addComponent(component: VelocityComponent(), to: weapon)
        world.addComponent(component: OwnerComponent(ownerEntity: owner, offset: offset), to: weapon)
        let facingOfOwner = world.getComponent(type: FacingComponent.self, for: owner)!.facing
        world.addComponent(component: FacingComponent(facing: facingOfOwner), to: weapon)
        world.addComponent(component: WeaponTimingComponent(
            lastFiredAt: lastFiredAt,
            coolDownInterval: coolDownInterval,
            attackSpeed: 1
        ), to: weapon)
        world.addComponent(component: WeaponEffectsComponent(effects: [
            ConsumeManaEffect(amount: weaponManaCost),
            SpawnProjectileEffect(
                speed: projectileSpeed,
                effectiveRange: projectileEffectiveRange,
                damage: projectileDamage,
                spriteName: "normalHandgunBullet",
                collisionSize: SIMD2<Float>(6, 6)
            )
        ]), to: weapon)

        return (owner, weapon)
    }

    private func addMana(to owner: Entity, current: Float, max: Float = 100, regenRate: Float = 0) {
        var mana = ManaComponent(base: current, max: max, regenRate: regenRate)
        mana.value.current = current
        world.addComponent(component: mana, to: owner)
    }

    private func getSpawnedProjectiles() -> [Entity] {
        world.entities(with: ProjectileComponent.self)
    }

    // MARK: - Position and mirror offset

    func testWeaponPositionFollowsOwnerFacingRight() {
        let (_, weapon) = makeWeaponWithOwner(
            ownerPosition: SIMD2(100, 50),
            ownerVelocity: SIMD2(1, 0),
            offset: SIMD2(10, -5)
        )
        system.update(deltaTime: 0.1, world: world)
        let transform = world.getComponent(type: TransformComponent.self, for: weapon)!
        XCTAssertEqual(transform.position.x, 110, accuracy: 0.01)
        XCTAssertEqual(transform.position.y,  45, accuracy: 0.01)
    }

    func testWeaponOffsetXMirroredWhenFacingLeft() {
        let (_, weapon) = makeWeaponWithOwner(
            ownerPosition: SIMD2(100, 50),
            ownerVelocity: SIMD2(-1, 0),
            offset: SIMD2(10, -5)
        )
        system.update(deltaTime: 0.1, world: world)
        let transform = world.getComponent(type: TransformComponent.self, for: weapon)!
        XCTAssertEqual(transform.position.x, 90, accuracy: 0.01)
        XCTAssertEqual(transform.position.y, 45, accuracy: 0.01)
    }

    func testWeaponYOffsetUnchangedWhenFacingRight() {
        let (_, weapon) = makeWeaponWithOwner(ownerVelocity: SIMD2(1, 0), offset: SIMD2(10, -5))
        system.update(deltaTime: 0.1, world: world)
        let y = world.getComponent(type: TransformComponent.self, for: weapon)!.position.y
        XCTAssertEqual(y, -5, accuracy: 0.01)
    }

    func testWeaponYOffsetUnchangedWhenFacingLeft() {
        let (_, weapon) = makeWeaponWithOwner(ownerVelocity: SIMD2(-1, 0), offset: SIMD2(10, -5))
        system.update(deltaTime: 0.1, world: world)
        let y = world.getComponent(type: TransformComponent.self, for: weapon)!.position.y
        XCTAssertEqual(y, -5, accuracy: 0.01)
    }

    func testWeaponDefaultsFacingRightWhenVelocityIsZero() {
        let (_, weapon) = makeWeaponWithOwner(ownerVelocity: .zero, offset: SIMD2(10, -5))
        system.update(deltaTime: 0.1, world: world)
        let transform = world.getComponent(type: TransformComponent.self, for: weapon)!
        XCTAssertEqual(transform.position.x, 10, accuracy: 0.01)
        XCTAssertEqual(transform.position.y, -5, accuracy: 0.01)
    }

    func testWeaponTracksOwnerAfterOwnerMoves() {
        let (owner, weapon) = makeWeaponWithOwner(
            ownerPosition: SIMD2(0, 0),
            ownerVelocity: SIMD2(1, 0),
            offset: SIMD2(10, 0)
        )
        system.update(deltaTime: 0.1, world: world)
        world.modifyComponentIfExist(type: TransformComponent.self, for: owner) { $0.position = SIMD2(50, 0) }
        system.update(deltaTime: 0.1, world: world)
        let transform = world.getComponent(type: TransformComponent.self, for: weapon)!
        XCTAssertEqual(transform.position.x, 60, accuracy: 0.01)
    }

    // MARK: - Cooldown

    func testWeaponDoesNotFireBeforeCooldownElapses() {
        makeWeaponWithOwner(isShooting: true, coolDownInterval: 1.0, lastFiredAt: 0)
        system.update(deltaTime: 0.5, world: world)
        XCTAssertTrue(getSpawnedProjectiles().isEmpty)
    }

    func testWeaponFiresWhenCooldownElapsed() {
        makeWeaponWithOwner(isShooting: true, coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)
        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testWeaponUpdatesLastFiredAtAfterFiring() {
        let (_, weapon) = makeWeaponWithOwner(isShooting: true, coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)
        let weaponComp = world.getComponent(type: WeaponTimingComponent.self, for: weapon)!
        XCTAssertEqual(weaponComp.lastFiredAt, 1.0, accuracy: 0.001)
    }

    func testWeaponDoesNotFireAgainWithinCooldown() {
        makeWeaponWithOwner(isShooting: true, coolDownInterval: 1.0, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 0.5, world: world)
        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testWeaponFiresAgainAfterCooldownResets() {
        makeWeaponWithOwner(isShooting: true, coolDownInterval: 1.0, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 1.0, world: world)
        XCTAssertEqual(getSpawnedProjectiles().count, 2)
    }

    func testWeaponDoesNotFireWhenNotShooting() {
        makeWeaponWithOwner(isShooting: false, coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)
        XCTAssertTrue(getSpawnedProjectiles().isEmpty)
    }

    // MARK: - Mana gate

    func testWeaponBlockedWhenInsufficientMana() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 20
        )
        addMana(to: owner, current: 10, max: 100) // only 10, need 20

        system.update(deltaTime: 1.0, world: world)

        XCTAssertTrue(getSpawnedProjectiles().isEmpty)
    }

    func testWeaponFiresWhenManaExactlyEqualsToCost() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 20
        )
        addMana(to: owner, current: 20, max: 100)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testWeaponFiresWhenManaSufficient() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 10
        )
        addMana(to: owner, current: 50, max: 100)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testManaDeductedAfterFiring() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 15
        )
        addMana(to: owner, current: 50, max: 100)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: owner)!
        XCTAssertEqual(mana.value.current, 35, accuracy: 0.001)
    }

    func testManaNotDeductedWhenShotBlocked() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 20
        )
        addMana(to: owner, current: 10, max: 100)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: owner)!
        XCTAssertEqual(mana.value.current, 10, accuracy: 0.001)
    }

    func testOwnerWithoutManaComponentFiresFreely() {
        // No ManaComponent added — gate should not apply
        makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 99
        )

        system.update(deltaTime: 1.0, world: world)

        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    func testManaClampsToZeroNotNegative() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 10
        )
        addMana(to: owner, current: 10, max: 100)

        system.update(deltaTime: 1.0, world: world) // fires, mana 10 → 0
        system.update(deltaTime: 1.0, world: world) // blocked (0 < 10), mana stays 0

        let mana = world.getComponent(type: ManaComponent.self, for: owner)!
        XCTAssertEqual(mana.value.current, 0, accuracy: 0.001)
        XCTAssertEqual(getSpawnedProjectiles().count, 1)
    }

    // MARK: - Projectile carries correct values

    func testSpawnedProjectileHasDamageFromWeapon() {
        makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            projectileDamage: 42
        )
        system.update(deltaTime: 1.0, world: world)

        let contactDamage = world.getComponent(type: ContactDamageComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertEqual(contactDamage.damage, 42, accuracy: 0.001)
    }

    func testManaConsumedUsingWeaponEffectCost() {
        let (owner, _) = makeWeaponWithOwner(
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0,
            weaponManaCost: 18
        )
        addMana(to: owner, current: 100, max: 100)
        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: owner)!
        XCTAssertEqual(mana.value.current, 82, accuracy: 0.001)
    }

    // MARK: - Projectile basic checks

    func testSpawnedProjectileHasTransformAtOwnerPosition() {
        makeWeaponWithOwner(
            ownerPosition: SIMD2(50, 30),
            offset: .zero,
            isShooting: true,
            coolDownInterval: 0.5,
            lastFiredAt: 0
        )
        system.update(deltaTime: 1.0, world: world)

        let transform = world.getComponent(type: TransformComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertEqual(transform.position.x, 50, accuracy: 0.01)
        XCTAssertEqual(transform.position.y, 30, accuracy: 0.01)
    }

    func testSpawnedProjectileHasVelocityAlignedWithAimDirection() {
        makeWeaponWithOwner(isShooting: true, aimDirection: SIMD2(1, 0), coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)

        let velocity = world.getComponent(type: VelocityComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertGreaterThan(velocity.linear.x, 0)
        XCTAssertEqual(velocity.linear.y, 0, accuracy: 0.01)
    }

    func testSpawnedProjectileVelocityReflectsAimDirection() {
        makeWeaponWithOwner(isShooting: true, aimDirection: SIMD2(-1, 0), coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)

        let velocity = world.getComponent(type: VelocityComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertLessThan(velocity.linear.x, 0)
    }

    func testSpawnedProjectileHasSpriteComponent() {
        makeWeaponWithOwner(isShooting: true, coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: getSpawnedProjectiles()[0]))
    }

    func testSpawnedProjectileOwnerMatchesPlayerEntity() {
        let (owner, _) = makeWeaponWithOwner(isShooting: true, coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)

        let projectileOwner = world.getComponent(type: OwnerComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertEqual(projectileOwner.ownerEntity, owner)
    }

    func testSpawnedProjectileHasPositiveEffectiveRange() {
        makeWeaponWithOwner(isShooting: true, coolDownInterval: 0.5, lastFiredAt: 0)
        system.update(deltaTime: 1.0, world: world)

        let range = world.getComponent(type: EffectiveRangeComponent.self, for: getSpawnedProjectiles()[0])!
        XCTAssertGreaterThan(range.value.current, 0)
    }
}
