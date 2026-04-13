//
//  FacingComponent.swift
//  dungeonCrawler
//
//  Created by Letian on 20/3/26.
//

import Foundation
import simd

public class FacingComponent: Component {
    public var facing: FacingType

    public init(facing: FacingType) {
        self.facing = facing
    }

    public init() {
        // force unwrap here is safe since the enum has at least one case,
        // as randomElement() only returns nil for empty collections.
        self.facing = FacingType.allCases.randomElement()!
    }
}

public enum FacingType: CaseIterable {
    case right
    case upRight
    case up
    case upLeft
    case left
    case downLeft
    case down
    case downRight

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

    /// Derives the nearest 8-way facing from a direction vector.
    /// Returns `nil` if the vector is below the threshold.
    public static func from(vector: SIMD2<Float>, threshold: Float = 0.001) -> FacingType? {
        guard simd_length(vector) > threshold else { return nil }
        let angle = atan2f(vector.y, vector.x)
        let e = Float.pi / 8
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
