import Foundation
import simd

public final class WeaponSystem: System {
    public var dependencies: [System.Type] { [CollisionSystem.self] }
    
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

        // ── Fire loop ────────────────────────────────────────────────────────
        for (weaponEntity, timing, effectsComponent, ownerComponent, _, weaponRenderComponent) in world.entities(
            with: WeaponTimingComponent.self,
            and: WeaponEffectsComponent.self,
            and: OwnerComponent.self,
            and: TransformComponent.self,
            and: WeaponRenderComponent.self
        ) {
            let ownerEntity = ownerComponent.ownerEntity
            guard let ownerTransform = world.getComponent(type: TransformComponent.self, for: ownerEntity),
                  let ownerInput = world.getComponent(type: InputComponent.self, for: ownerEntity) else { continue }


            if let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: ownerEntity),
               equipped.primaryWeapon != weaponEntity {
                continue
            }

            let ownerFacing: AnimationDirection
            if let anim = world.getComponent(type: AnimationComponent.self, for: ownerEntity) {
                ownerFacing = AnimationDirection(animationDirection: anim.lastDirection)
            } else {
                ownerFacing = world.getComponent(type: FacingComponent.self, for: ownerEntity)?.facing ?? .right
            }

            let aimDir = ownerInput.aimDirection
            let aimAngle = atan2(aimDir.y, aimDir.x)
            let isFiring = ownerInput.isShooting
            let weaponFacing: AnimationDirection
            if isFiring, let aimFacing = AnimationDirection.from(vector: aimDir) {
                weaponFacing = aimFacing
            } else {
                weaponFacing = ownerFacing
            }
            let isLeft = weaponFacing.isLeft

            if let sprite = world.getComponent(type: SpriteComponent.self, for: weaponEntity),
               sprite.layer == .weaponBack || sprite.layer == .weaponFront {
                sprite.layer = isLeft ? .weaponBack : .weaponFront
            }

            let mirroredOffset = SIMD2<Float>(
                isLeft ? -weaponRenderComponent.offset.x : weaponRenderComponent.offset.x,
                weaponRenderComponent.offset.y
            )

            let initRotationOffset = world.getComponent(type: WeaponRenderComponent.self, for: weaponEntity)?
                .initRotation ?? 0
            let mirroredInitRotation = isLeft ? -initRotationOffset : initRotationOffset

            let defaultWeaponRotation = isLeft ? (aimAngle - .pi) : aimAngle
            var renderedRotation = defaultWeaponRotation + mirroredInitRotation

            if let swing = world.getComponent(type: WeaponSwingComponent.self, for: weaponEntity) {
                let progressedElapsed = swing.elapsed + delta
                if progressedElapsed >= swing.duration {
                    world.removeComponent(type: WeaponSwingComponent.self, from: weaponEntity)
                } else {
                    let progress = progressedElapsed / swing.duration
                    let offset = sin(2 * (0.25 - progress) * .pi) * swing.amplitude * swing.directionSign
                    renderedRotation = swing.baseRotation + offset
                    swing.elapsed = progressedElapsed
                }
            }

            if let transform = world.getComponent(type: TransformComponent.self, for: weaponEntity) {
                transform.position = ownerTransform.position + mirroredOffset
                transform.rotation = renderedRotation
            }

            world.getComponent(type: FacingComponent.self, for: weaponEntity)?.facing = weaponFacing

            guard ownerInput.isShooting else { continue }
            guard isReadyToFire(gameTime: gameTime, timing: timing) else { continue }

            var fireDirection = aimDir
            let epsilon: Float = 0.001
            if simd_length_squared(fireDirection) < epsilon * epsilon {
                fireDirection = isLeft ? SIMD2<Float>(-1, 0) : SIMD2<Float>(1, 0)
            } // don't update when the aim displacement is too small
            let projectileSpawnPosition = ownerTransform.position + mirroredOffset

            let fireContext = FireContext(
                owner: ownerEntity,
                weapon: weaponEntity,
                fireDirection: fireDirection,
                firePosition: projectileSpawnPosition,
                gameTime: gameTime,
                world: world
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

    // MARK: - Helpers

    private func isReadyToFire(gameTime: Float, timing: WeaponTimingComponent) -> Bool {
        guard let cooldown = timing.coolDownInterval else { return true }
        return (gameTime - timing.lastFiredAt) >= Float(cooldown)
    }
}
