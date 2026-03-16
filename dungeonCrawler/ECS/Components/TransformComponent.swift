//
//  TransformComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd // simd is used for integration with SpriteKit
import CoreGraphics

/// "Where is this entity and which way does it face?"
public struct TransformComponent: Component {
    public var position: SIMD2<Float>

    /// Rotation in radians. 0 = facing right, positive = counter-clockwise.
    public var rotation: Float

    /// scale factor. 1.0 = original size.
    public var scale: Float

    public init(
        position: SIMD2<Float> = .zero,
        rotation: Float = 0,
        scale: Float = 1
    ) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }

    // Convenience accessor for SpriteKit bridge.
    public var cgPoint: CGPoint {
        CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
    }
}
