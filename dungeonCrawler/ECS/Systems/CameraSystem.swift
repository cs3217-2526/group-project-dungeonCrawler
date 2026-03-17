
import Foundation
import simd

/// Lerps the ViewportComponent position toward the entity tagged with
/// CameraFocusComponent. Runs before rendering (priority 90).
public final class CameraSystem: System {

    public let priority: Int = 90

    /// Controls smoothness. Higher = snappier (~20 is nearly instant).
    public var smoothing: Float = 8.0

    public init() {}

    public func update(deltaTime: Double, world: World) {
        // Find the entity to follow.
        let targets = world.entities(with: TransformComponent.self, and: CameraFocusComponent.self)
        guard let (_, transform, focus) = targets.first else { return }
        let targetPosition = transform.position + focus.lookOffset

        // Find the camera entity and lerp its ViewportComponent toward the target.
        let cameras = world.entities(with: ViewportComponent.self)
        guard let cameraEntity = cameras.first else { return }

        world.modifyComponent(type: ViewportComponent.self, for: cameraEntity) { viewport in
            let t = min(smoothing * Float(deltaTime), 1.0)
            viewport.position = viewport.position + (targetPosition - viewport.position) * t
        }
    }
}
