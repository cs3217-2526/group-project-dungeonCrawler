import Foundation
import simd

public final class WeaponSystem: System {
    public var dependencies: [System.Type] { [CollisionSystem.self] }
    
    private var gameTime: Float

    public init() {
        self.gameTime = 0
    }

    public func update(deltaTime: Foundation.TimeInterval, world: World) {
        self.gameTime += Float(deltaTime)

        for (weaponEntity, timing, effectsComponent, ownerComponent, _, _) in world.entities(
            with: WeaponTimingComponent.self,
            and: WeaponEffectsComponent.self,
            and: OwnerComponent.self,
            and: FacingComponent.self,
            and: TransformComponent.self
        ) {
            let ownerEntity = ownerComponent.ownerEntity
            guard let ownerTransform = world.getComponent(type: TransformComponent.self, for: ownerEntity),
                  let ownerInput = world.getComponent(type: InputComponent.self, for: ownerEntity) else { continue }

            let ownerFacing = world.getComponent(type: FacingComponent.self, for: ownerEntity)
            let facingRight = ownerFacing?.facing != .left

            let mirroredOffset = SIMD2<Float>(
                facingRight ? ownerComponent.offset.x : -ownerComponent.offset.x,
                ownerComponent.offset.y
            )

            let aimDir = ownerInput.aimDirection
            let weaponRotation: Float = simd_length(aimDir) > 0.001
                ? (facingRight ? atan2(aimDir.y, aimDir.x) : -atan2(aimDir.y, -aimDir.x))
                : 0

            world.modifyComponent(type: TransformComponent.self, for: weaponEntity) { transform in
                transform.position = ownerTransform.position + mirroredOffset
                transform.rotation = weaponRotation
            }

            world.modifyComponent(type: FacingComponent.self, for: weaponEntity) { facing in
                facing.facing = facingRight ? .right : .left
            }

            if let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: ownerEntity),
               equipped.primaryWeapon != weaponEntity {
                continue
            }

            guard ownerInput.isShooting else { continue }
            guard isReadyToFire(gameTime: gameTime, timing: timing) else { continue }

            var fireDirection = ownerInput.aimDirection
            let epsilon: Float = 0.001
            if simd_length_squared(fireDirection) < epsilon * epsilon {
                fireDirection = facingRight ? SIMD2<Float>(1, 0) : SIMD2<Float>(-1, 0)
            }
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

            guard !blocked else { continue }

            world.modifyComponent(type: WeaponTimingComponent.self, for: weaponEntity) { timing in
                timing.lastFiredAt = gameTime
            }
        }
    }

    private func isReadyToFire(gameTime: Float, timing: WeaponTimingComponent) -> Bool {
        guard let cooldown = timing.coolDownInterval else { return true }
        return (gameTime - timing.lastFiredAt) >= Float(cooldown)
    }
}
