import simd

/// The eight movement directions used by the character animation system.
/// `rawValue` is the capitalised suffix appended to "walk" / "idle" to form animation keys.
public enum AnimationDirection: String, CaseIterable {
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
    public static func from(vector: SIMD2<Float>, threshold: Float = 5.0) -> AnimationDirection? {
        guard simd_length(vector) > threshold else { return nil }
        let angle = atan2f(vector.y, vector.x)
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
    
    /// Angle in radians from the +x axis, matching the 8-way compass.
    public var angle: Float {
        switch self {
        case .right: return 0
        case .upRight: return .pi / 4
        case .up: return .pi / 2
        case .upLeft: return 3 * .pi / 4
        case .left: return .pi
        case .downLeft: return -3 * .pi / 4
        case .down: return -.pi / 2
        case .downRight: return -.pi / 4
        }
    }
    
    /// True when the facing has a leftward horizontal component.
    public var isLeft: Bool {
        switch self {
        case .left, .upLeft, .downLeft, .up, .down: return true
        default: return false
        }
    }
    
    public init(animationDirection: AnimationDirection) {
        switch animationDirection {
        case .right:
            self = .right
        case .upRight:
            self = .upRight
        case .up:
            self = .up
        case .upLeft:
            self = .upLeft
        case .left:
            self = .left
        case .downLeft:
            self = .downLeft
        case .down:
            self = .down
        case .downRight:
            self = .downRight
        }
    }
}
