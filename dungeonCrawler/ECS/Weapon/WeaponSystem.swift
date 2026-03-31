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

        for (weaponEntity, weaponComponent, ownerComponent, _, _) in world.entities(
            with: WeaponComponent.self,
            and: OwnerComponent.self,
            and: FacingComponent.self,
            and: TransformComponent.self) {
            let ownerEntity = ownerComponent.ownerEntity
            guard let ownerTransform = world.getComponent(type: TransformComponent.self, for: ownerEntity),
                  let ownerInput = world.getComponent(type: InputComponent.self, for: ownerEntity) else { continue }

            let ownerFacing = world.getComponent(type: FacingComponent.self, for: ownerEntity)
            let facingRight = ownerFacing?.facing != .left

            let mirroredOffset = SIMD2<Float>(
                facingRight ? ownerComponent.offset.x : -ownerComponent.offset.x,
                ownerComponent.offset.y
            )

            // Mirror the aim angle when facing left so it works correctly with xScale flip.
            let aimDir = ownerInput.aimDirection
            let weaponRotation: Float = simd_length(aimDir) > 0.001
                ? (facingRight ? atan2(aimDir.y, aimDir.x) : -atan2(aimDir.y, -aimDir.x))
                : 0

            world.modifyComponent(type: TransformComponent.self, for: weaponEntity) { transform in
                transform.position = ownerTransform.position + mirroredOffset
                transform.rotation = weaponRotation
            }

            // Update weapon facing to match the owner's
            // so syncNode's flipFactor logic flips the weapon sprite
            world.modifyComponent(type: FacingComponent.self, for: weaponEntity) { facing in
                facing.facing = facingRight ? .right : .left
            }
            
            // Only fire if this weapon is the owner's primary weapon
            if let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: ownerEntity),
               equipped.primaryWeapon != weaponEntity {
                continue
            }

            if ownerInput.isShooting {
                let isReadyToFire: Bool = (gameTime - weaponComponent.lastFiredAt) >= Float(weaponComponent.coolDownInterval)
                guard isReadyToFire else { continue }
                 
                // Block firing if the owner has a ManaComponent but not enough mana
                if let mana = world.getComponent(type: ManaComponent.self, for: ownerEntity) {
                    guard mana.value.current >= weaponComponent.manaCost else { continue }
                }
 
                var fireDirection = ownerInput.aimDirection
                let epsilon: Float = 0.001
                if simd_length_squared(fireDirection) < epsilon * epsilon {
                    fireDirection = facingRight ? SIMD2<Float>(1, 0) : SIMD2<Float>(-1, 0)
                }

                world.modifyComponent(type: ManaComponent.self, for: ownerEntity) { mana in
                    mana.value.current -= weaponComponent.manaCost
                    mana.value.clampToMin()
                    print("current mana value: \(mana.value)")
                }
                
                world.modifyComponent(type: WeaponComponent.self, for: weaponEntity) { weapon in
                    weapon.lastFiredAt = gameTime
                }
                
                // Only for projectile weapon now
                ProjectileEntityFactory(
                    from: ownerTransform.position,
                    aimAt: fireDirection,
                    speed: 300,
                    effectiveRange: 400,
                    damage: weaponComponent.damage,
                    manaCost: weaponComponent.manaCost,
                    owner: ownerEntity
                ).make(in: world)
                
            }
        }
    }
}
