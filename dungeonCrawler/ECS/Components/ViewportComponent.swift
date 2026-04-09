//
//  ViewportComponent.swift
//  dungeonCrawler
//

import Foundation
import simd

/// Camera state written by CameraSystem each frame.
/// SpriteKit adapter reads this to move worldLayer.
public class ViewportComponent: Component {
    public var position: SIMD2<Float>
    public var zoom: Float = 1.0
    public var rotation: Float = 0.0

    public init(position: SIMD2<Float> = .zero, zoom: Float = 1.0, rotation: Float = 0.0) {
        self.position = position
        self.zoom = zoom
        self.rotation = rotation
    }
}
