//
//  SpriteKitCameraAdapter.swift
//  dungeonCrawler
//

import SpriteKit

/// Reads a ViewportComponent and shifts worldLayer so the camera position
/// is centered on screen. No SKCameraNode required.
final class SpriteKitCameraAdapter {

    private weak var worldLayer: SKNode?

    init(worldLayer: SKNode) {
        self.worldLayer = worldLayer
    }

    func apply(viewport: ViewportComponent, screenCenter: CGPoint) {
        let scale = CGFloat(viewport.zoom)
        worldLayer?.position = CGPoint(
            x: screenCenter.x - CGFloat(viewport.position.x) * scale,
            y: screenCenter.y - CGFloat(viewport.position.y) * scale
        )
        worldLayer?.xScale = scale
        worldLayer?.yScale = scale
        worldLayer?.zRotation = CGFloat(-viewport.rotation)
    }
}
