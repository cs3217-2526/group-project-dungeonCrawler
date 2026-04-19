import Foundation

/// Gates firing behind a charge-up timer. While the owner holds the fire input,
/// elapsed accumulates; once it reaches `required`, the effect passes through
/// and downstream effects (e.g. MeleeDamageEffect) run. Charge resets after
/// a successful fire and whenever the owner releases the fire input
/// (handled by WeaponSystem).
struct ChargeEffect: WeaponEffect {
    let required: Float

    func apply(context: FireContext) -> FireEffectResult {
        guard let charge = context.world.getComponent(type: WeaponChargeComponent.self, for: context.weapon) else {
            return .blocked("no_charge_component")
        }

        charge.elapsed += context.delta

        if charge.elapsed >= charge.required {
            charge.elapsed = 0
            return .success
        }

        return .blocked("charging")
    }
}
