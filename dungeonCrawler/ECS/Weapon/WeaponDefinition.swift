import Foundation
import simd

/// Core definition of a weapon's static data.
/// Instantiated from WeaponLibrary (player weapons) or WeaponPresets (enemy weapons).
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
    /// Non-nil only for firearms. Used by WeaponEntityFactory to attach WeaponAmmoComponent.
    let ammoConfig: AmmoConfig?

    public init(
        textureName: String,
        offset: SIMD2<Float>,
        scale: Float,
        lastFiredAt: Float?,
        cooldown: TimeInterval?,
        attackSpeed: Float?,
        effects: [any WeaponEffect],
        anchorPoint: SIMD2<Float>?,
        initRotation: Float?,
        ammoConfig: AmmoConfig? = nil
    ) {
        self.textureName = textureName
        self.offset = offset
        self.scale = scale
        self.lastFiredAt = lastFiredAt
        self.cooldown = cooldown
        self.attackSpeed = attackSpeed
        self.effects = effects
        self.anchorPoint = anchorPoint
        self.initRotation = initRotation
        self.ammoConfig = ammoConfig
    }
}
