import Foundation
import simd

/// Single source of truth for "where is the owner aiming their weapon?".
///
/// Rule: `aim > move > fallbackFacing`. The returned direction is always unit length,
/// so downstream callers can feed it to `atan2` or use it as a fire direction without
/// re-normalizing.
public enum WeaponAimResolver {

    public struct Resolved {
        public let direction: SIMD2<Float>
        public let facing: AnimationDirection
    }

    private static let epsilon: Float = 0.001

    public static func resolve(input: InputComponent, fallbackFacing: AnimationDirection) -> Resolved {
        let rawDirection: SIMD2<Float>
        if simd_length(input.aimDirection) > epsilon {
            rawDirection = input.aimDirection
        } else if simd_length(input.moveDirection) > epsilon {
            rawDirection = input.moveDirection
        } else {
            rawDirection = SIMD2<Float>(cos(fallbackFacing.angle), sin(fallbackFacing.angle))
        }

        let direction = simd_normalize(rawDirection)
        // Inputs are unit-length, so override the default 5.0 threshold; fall back when below epsilon.
        let facing = AnimationDirection.from(vector: direction, threshold: epsilon) ?? fallbackFacing
        return Resolved(direction: direction, facing: facing)
    }
}
