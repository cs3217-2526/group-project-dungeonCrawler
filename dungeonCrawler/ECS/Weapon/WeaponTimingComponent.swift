import Foundation
import simd

public class WeaponTimingComponent: Component {
    var coolDownInterval: TimeInterval?
    var attackSpeed: Float?
    var lastFiredAt: Float
    init(lastFiredAt: Float,
         coolDownInterval: TimeInterval?,
         attackSpeed: Float?) {
        self.lastFiredAt = lastFiredAt
        self.coolDownInterval = coolDownInterval
        self.attackSpeed = attackSpeed
    }
}
