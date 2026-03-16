//
//  CameraSystem.swift
//  dungeonCrawler
//
//
//  Created by gerteck on 17/3/26.
//

import Foundation
import SpriteKit
import simd

/// Shifts scene's SKCameraNode toward entity tagged with
/// CameraFocusComponent. Runs before rendering (100).
public final class CameraSystem: System {

    public let priority: Int = 90

    private weak var cameraNode: SKCameraNode?

    /// Controls speed smoothness. Higher = snappier / more instant (~20). 
    public var smoothing: Float = 8.0

    public init(cameraNode: SKCameraNode) {
        self.cameraNode = cameraNode
    }

    public func update(deltaTime: Double, world: World) {
        guard let cameraNode else { return }

        let targets = world.entities(with: TransformComponent.self, and: CameraFocusComponent.self)
        guard let (_, transform, focus) = targets.first else { return }

        let target  = transform.position + focus.lookOffset
        let current = SIMD2<Float>(Float(cameraNode.position.x), Float(cameraNode.position.y))
        let t       = min(smoothing * Float(deltaTime), 1.0)
        let next    = current + (target - current) * t

        cameraNode.position = CGPoint(x: CGFloat(next.x), y: CGFloat(next.y))
    }
}
