//
//  SpriteComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

public struct SpriteComponent: Component {
    /// Asset catalog name for the entity's texture.
    public var textureName: String

    /// RGBA tint applied on top of the texture. Default = opaque white (no tint).
    public var tintRed: Float
    public var tintGreen: Float
    public var tintBlue: Float
    public var tintAlpha: Float

    public init(
        textureName: String,
        tintRed: Float = 1, tintGreen: Float = 1,
        tintBlue: Float = 1, tintAlpha: Float = 1
    ) {
        self.textureName = textureName
        self.tintRed = tintRed
        self.tintGreen = tintGreen
        self.tintBlue = tintBlue
        self.tintAlpha = tintAlpha
    }
}
