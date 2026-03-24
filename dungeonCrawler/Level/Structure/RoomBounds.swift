//
//  RoomBounds.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/3/26.
//

import Foundation
import simd

public struct RoomBounds {
    /// Bottom-left corner in world coordinates
    public var origin: SIMD2<Float>
    
    /// Width and height of the room
    public var size: SIMD2<Float>
    
    public init(origin: SIMD2<Float>, size: SIMD2<Float>) {
        self.origin = origin
        self.size = SIMD2<Float>(Swift.max(0, size.x), Swift.max(0, size.y))
    }
    
    // Edge Accessors
    public var minX: Float { origin.x }
    public var maxX: Float { max.x }
    public var minY: Float { origin.y }
    public var maxY: Float { max.y }
    
    /// Center point of the room
    public var center: SIMD2<Float> {
        origin + size / 2
    }
    
    /// Maximum corner (top-right)
    public var max: SIMD2<Float> {
        origin + size
    }

    /// Check if a point is inside this room
    public func contains(_ point: SIMD2<Float>) -> Bool {
        point.x >= minX && point.x <= maxX &&
        point.y >= minY && point.y <= maxY
    }
    
    /// Returns a new `RoomBounds` shrunk by `amount` on all sides.
    public func inset(by amount: Float) -> RoomBounds {
        RoomBounds(
            origin: origin + SIMD2<Float>(amount, amount),
            size: size - SIMD2<Float>(amount * 2, amount * 2)
        )
    }
    
    /// Returns a point along a specific wall based on a percentage (0.0 to 1.0).
    public func pointOnWall(_ direction: Direction, position: Float) -> SIMD2<Float> {
        let p = Swift.max(0, Swift.min(1, position))
        switch direction {
        case .north: return SIMD2<Float>(minX + size.x * p, maxY)
        case .south: return SIMD2<Float>(minX + size.x * p, minY)
        case .west:  return SIMD2<Float>(minX, minY + size.y * p)
        case .east:  return SIMD2<Float>(maxX, minY + size.y * p)
        }
    }
    
    /// Get a random position within the room (using a custom generator).
    public func randomPosition(margin: Float = 50, using generator: inout SeededGenerator) -> SIMD2<Float> {
        let safeArea = inset(by: margin)
        guard safeArea.size.x > 0 && safeArea.size.y > 0 else { return center }
        let x = Float.random(in: safeArea.minX...safeArea.maxX, using: &generator)
        let y = Float.random(in: safeArea.minY...safeArea.maxY, using: &generator)
        return SIMD2<Float>(x, y)
    }

    /// Calculates the bounds for a new room adjacent to this one in a specific direction.
    ///
    /// - Parameters:
    ///   - direction: The direction to place the new room relative to this one.
    ///   - spacing: The distance (corridor length) between the two rooms.
    ///   - size: The dimensions of the new room.
    /// - Returns: A new `RoomBounds` correctly positioned in world space.
    public func adjacentBounds(
        direction: Direction,
        spacing: Float,
        size: SIMD2<Float>
    ) -> RoomBounds {
        var origin = self.origin

        switch direction {
        case .east:
            origin.x = self.max.x + spacing
            origin.y = self.center.y - size.y / 2
        case .west:
            origin.x = self.origin.x - spacing - size.x
            origin.y = self.center.y - size.y / 2
        case .north:
            origin.y = self.max.y + spacing
            origin.x = self.center.x - size.x / 2
        case .south:
            origin.y = self.origin.y - spacing - size.y
            origin.x = self.center.x - size.x / 2
        }

        return RoomBounds(origin: origin, size: size)
    }
}
