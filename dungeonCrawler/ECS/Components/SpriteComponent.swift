//
//  SpriteComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import CoreGraphics

/// Defines what to render.
public enum SpriteContent: Equatable {
    case texture(name: String)
    case solidColor(color: SIMD4<Float>)
}

/// Defines the Z-position layering conceptually.
public enum RenderLayer: CGFloat {
    case floor = 0
    case wall = 1
    case obstacle = 2
    case pickUp = 3
    case projectile = 5
    case entity = 6
    case weapon = 7
    case ui = 10
}

public class SpriteComponent: Component {
    public var content: SpriteContent
    public var tint: SIMD4<Float>
    public var layer: RenderLayer
    public var renderSize: SIMD2<Float>?
    public var anchorPoint: SIMD2<Float>

    public init(
        content: SpriteContent,
        tint: SIMD4<Float> = SIMD4(1, 1, 1, 1),
        layer: RenderLayer = .entity,
        renderSize: SIMD2<Float>? = nil,
        anchorPoint: SIMD2<Float> = SIMD2(0.5, 0.5)
    ) {
        self.content = content
        self.tint = tint
        self.layer = layer
        self.renderSize = renderSize
        self.anchorPoint = anchorPoint
    }
    
    // Legacy initializer to ease migration for texture-based sprites
    public init(
        textureName: String,
        tintRed: Float = 1, tintGreen: Float = 1,
        tintBlue: Float = 1, tintAlpha: Float = 1,
        renderSize: SIMD2<Float>? = nil, 
        zPosition: CGFloat = 1
    ) {
        self.content = .texture(name: textureName)
        self.tint = SIMD4(tintRed, tintGreen, tintBlue, tintAlpha)
        self.renderSize = renderSize
        self.anchorPoint = SIMD2(0.5, 0.5)
        // Best effort layer mapping fallback
        switch zPosition {
        case 0: self.layer = .floor
        case 1: self.layer = .wall
        case 4: self.layer = .weapon
        case 5: self.layer = .projectile
        default: self.layer = .entity
        }
    }
}

// MARK: - Convenience presets for map geometry
 
public extension SpriteComponent {
    /// Solid black rectangle — used for perimeter walls.
    static func wall(size: SIMD2<Float>) -> SpriteComponent {
        SpriteComponent(
            content: .solidColor(color: SIMD4(0, 0, 0, 1)),
            layer: .wall,
            renderSize: size
        )
    }
 
    /// Solid dark-green rectangle — used for the floor fill.
    static func floor(size: SIMD2<Float>) -> SpriteComponent {
        SpriteComponent(
            content: .solidColor(color: SIMD4(0.13, 0.25, 0.13, 1)),
            layer: .floor,
            renderSize: size
        )
    }

    /// Solid brown rectangle — used for room obstacles when no texture is available.
    static func obstacle(size: SIMD2<Float>) -> SpriteComponent {
        SpriteComponent(
            content: .solidColor(color: SIMD4(0.45, 0.30, 0.15, 1)),
            layer: .obstacle,
            renderSize: size
        )
    }
}
