import Foundation
import simd

public final class WeaponEffectSystem: System {
    public var dependencies: [System.Type] { [CollisionSystem.self, WeaponAnimationSystem.self] }

    private var gameTime: Float

    public init() {
        self.gameTime = 0
    }

    public func update(deltaTime: Double, world: World) {
        self.gameTime += Float(deltaTime)
        let delta = Float(deltaTime)

        // ── Reload tick ──────────────────────────────────────────────────────
        // Runs every frame for all weapon entities that are currently reloading.
        // Kept separate from the fire loop so reload progresses even when the
        // player is not shooting.
        tickReloads(delta: delta, world: world)

        resetChargesWhenNotFiring(world: world)

        // ── Fire loop ────────────────────────────────────────────────────────
        for (weaponEntity, timing, effectsComponent, ownerComponent, _) in world.entities(
            with: WeaponTimingComponent.self,
            and: WeaponEffectsComponent.self,
            and: OwnerComponent.self,
            and: TransformComponent.self,
        ) {
            let ownerEntity = ownerComponent.ownerEntity
            guard let ownerInput = world.getComponent(type: InputComponent.self, for: ownerEntity) else { continue }

            if let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: ownerEntity),
               equipped.primaryWeapon != weaponEntity {
                continue
            }

            guard ownerInput.isShooting else { continue }
            guard isReadyToFire(gameTime: gameTime, timing: timing) else { continue }

            let ownerFacing: AnimationDirection
            if let anim = world.getComponent(type: AnimationComponent.self, for: ownerEntity) {
                ownerFacing = AnimationDirection(animationDirection: anim.lastDirection)
            } else {
                ownerFacing = world.getComponent(type: FacingComponent.self, for: ownerEntity)?.facing ?? .right
            }

            let resolved = WeaponAimResolver.resolve(input: ownerInput, fallbackFacing: ownerFacing)

            let projectileSpawnPosition = world.getComponent(type: TransformComponent.self, for: weaponEntity)?.position
                ?? world.getComponent(type: TransformComponent.self, for: ownerEntity)?.position
                ?? .zero

            let fireContext = FireContext(
                owner: ownerEntity,
                weapon: weaponEntity,
                fireDirection: resolved.direction,
                firePosition: projectileSpawnPosition,
                gameTime: gameTime,
                world: world,
                delta: delta
            )

            var blocked = false
            for effect in effectsComponent.effects {
                let result = effect.apply(context: fireContext)
                if case .blocked = result {
                    blocked = true
                    break
                }
            }

            if !blocked {
                timing.lastFiredAt = gameTime
            }
        }
    }

    // MARK: - Reload

    private func tickReloads(delta: Float, world: World) {
        for (weaponEntity) in world.entities(with: WeaponAmmoComponent.self) {
            guard let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: weaponEntity) else { continue }

            guard ammo.isReloading else { continue }

            ammo.reloadElapsed += delta

            if ammo.reloadElapsed >= ammo.reloadTime {
                ammo.currentAmmo = ammo.magazineSize
                ammo.isReloading = false
                ammo.reloadElapsed = 0
            }
        }
    }

    private func resetChargesWhenNotFiring(world: World) {
        for weaponEntity in world.entities(with: WeaponChargeComponent.self) {
            guard let charge = world.getComponent(type: WeaponChargeComponent.self, for: weaponEntity) else { continue }

            let ownerEntity = world.getComponent(type: OwnerComponent.self, for: weaponEntity)?.ownerEntity
            let isFiring = ownerEntity.flatMap { world.getComponent(type: InputComponent.self, for: $0)?.isShooting } ?? false

            if !isFiring {
                charge.elapsed = 0
            }
        }
    }

    // MARK: - Helpers

    private func isReadyToFire(gameTime: Float, timing: WeaponTimingComponent) -> Bool {
        guard let cooldown = timing.coolDownInterval else { return true }
        return (gameTime - timing.lastFiredAt) >= Float(cooldown)
    }
}
