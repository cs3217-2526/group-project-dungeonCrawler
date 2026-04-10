import Foundation
import simd

public struct WeaponBase {
    let textureName: String
    let offset: SIMD2<Float>
    let scale: Float
    let lastFiredAt: Float?
    let cooldown: TimeInterval?
    let attackSpeed: Float?
    let effects: [WeaponEffect]
    let anchorPoint: SIMD2<Float>?
    let initRotation: Float?
}
