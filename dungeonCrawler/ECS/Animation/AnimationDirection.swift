import simd

/// The eight movement directions used by the character animation system.
/// `rawValue` is the capitalised suffix appended to "walk" / "idle" to form animation keys.
public enum AnimationDirection: String {
    case right     = "Right"
    case upRight   = "UpRight"
    case up        = "Up"
    case upLeft    = "UpLeft"
    case left      = "Left"
    case downLeft  = "DownLeft"
    case down      = "Down"
    case downRight = "DownRight"

    /// Derives the nearest direction from a movement vector using 45° sectors.
    /// Returns `nil` if the vector is zero (caller should keep the previous direction).
    public static func from(velocity: SIMD2<Float>, threshold: Float = 5.0) -> AnimationDirection? {
        guard simd_length(velocity) > threshold else { return nil }
        let angle = atan2f(velocity.y, velocity.x)
        let e = Float.pi / 8   // 22.5° per sector
        if      angle > -e      && angle <=  e      { return .right     }
        else if angle >  e      && angle <=  3 * e  { return .upRight   }
        else if angle >  3 * e  && angle <=  5 * e  { return .up        }
        else if angle >  5 * e  && angle <=  7 * e  { return .upLeft    }
        else if angle > -3 * e  && angle <= -e      { return .downRight }
        else if angle > -5 * e  && angle <= -3 * e  { return .down      }
        else if angle > -7 * e  && angle <= -5 * e  { return .downLeft  }
        else                                         { return .left      }
    }
}
