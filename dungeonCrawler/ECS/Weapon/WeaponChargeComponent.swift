import Foundation

/// Tracks charge progress for weapons that need to build up strength before firing.
/// Attached by WeaponEntityFactory when the weapon's effects include a ChargeEffect.
public class WeaponChargeComponent: Component {
    var required: Float
    var elapsed: Float

    public init(required: Float, elapsed: Float = 0) {
        self.required = required
        self.elapsed = elapsed
    }
}
