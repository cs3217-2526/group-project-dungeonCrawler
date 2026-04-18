import Foundation
import simd

public struct WeaponBase {
    let textureName: String
    let offset: SIMD2<Float>
    let scale: Float
    let lastFiredAt: Float?
    let cooldown: TimeInterval?
    let attackSpeed: Float?
    let effects: [any WeaponEffect]
    let anchorPoint: SIMD2<Float>?
    let initRotation: Float?
}

public extension WeaponBase {
 
    /// Basic ranged weapon used by the Ranger enemy.
    /// Fires a slow projectile with a short cooldown.
    static let enemyRangedDefault = WeaponBase(
        textureName: "EnemyBullet",
        offset: .zero,          // centred on the enemy — no visible held weapon
        scale: 1.0,
        lastFiredAt: nil,
        cooldown: 0.5,
        attackSpeed: 150,
        effects: [
            SpawnProjectileEffect(
                speed: 180,
                effectiveRange: 300,
                damage: 8,
                spriteName: "normalHandgunBullet",
                collisionSize: SIMD2<Float>(6, 6)
            )
        ],
        anchorPoint: SIMD2<Float>(0.5, 0.5),
        initRotation: 0
    )
    
    /// Attack weapon used by the Tower enemy.
    /// Fires a fast projectile with a short cooldown.
    static let towerAttack = WeaponBase(
        textureName: "EnemyBullet",
        offset: .zero,          // centred on the enemy — no visible held weapon
        scale: 1.0,
        lastFiredAt: nil,
        cooldown: 0.2,
        attackSpeed: 200,
        effects: [
            SpawnProjectileEffect(
                speed: 250,
                effectiveRange: 300,
                damage: 8,
                spriteName: "normalHandgunBullet",
                collisionSize: SIMD2<Float>(6, 6)
            )
        ],
        anchorPoint: SIMD2<Float>(0.5, 0.5),
        initRotation: 0
    )
}
 
