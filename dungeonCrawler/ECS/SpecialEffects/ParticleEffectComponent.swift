import Foundation

/// Drives a one-shot frame animation on an entity.
/// When the last frame is reached the entity is queued for destruction
/// by `ParticleEffectSystem`.
public final class ParticleEffectComponent: Component {
    public let frameNames: [String]
    public let frameDuration: Double
    public private(set) var frameIndex: Int = 0
    public private(set) var elapsed: Double = 0
    public private(set) var isFinished: Bool = false

    public init(frameNames: [String], frameDuration: Double) {
        self.frameNames    = frameNames
        self.frameDuration = frameDuration
    }

    public func advance(by deltaTime: Double) {
        guard !isFinished else { return }
        elapsed += deltaTime
        if elapsed >= frameDuration {
            elapsed -= frameDuration
            frameIndex += 1
            if frameIndex >= frameNames.count {
                isFinished = true
            }
        }
    }

    public var currentFrameName: String? {
        guard frameIndex < frameNames.count else { return nil }
        return frameNames[frameIndex]
    }
}
