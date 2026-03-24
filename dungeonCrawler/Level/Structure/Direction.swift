import Foundation
import simd

public enum Direction {
    case north, south, east, west
    
    /// A unit vector pointing in enum direction.
    public var vector: SIMD2<Float> {
        switch self {
        case .north: return SIMD2<Float>(0, 1)
        case .south: return SIMD2<Float>(0, -1)
        case .east:  return SIMD2<Float>(1, 0)
        case .west:  return SIMD2<Float>(-1, 0)
        }
    }

    public var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east:  return .west
        case .west:  return .east
        }
    }
}
