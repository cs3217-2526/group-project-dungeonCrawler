import Foundation

/// Drives sprite frame animation for an entity.
///
/// `animations` maps animation keys (e.g. "walkDown", "idleRight") to ordered arrays of
/// texture-cache names. `AnimationSystem` advances the frame timer and writes the current
/// frame name into the entity's `SpriteComponent` each tick.
public final class AnimationComponent: Component {

    /// All available animations for this entity.
    /// Key: animation name (e.g. "walkDown"). Value: ordered texture-cache name array.
    public let animations: [String: [String]]

    /// Seconds each frame is displayed before advancing.
    public let frameDuration: Double

    /// The animation key that is currently playing (e.g. "walkDown", "idleRight").
    public var currentAnimation: String

    /// The last resolved movement direction — used to keep idle facing consistent.
    public var lastDirection: AnimationDirection

    /// Index into `animations[currentAnimation]`.
    public var frameIndex: Int = 0

    /// Accumulated time (seconds) since the last frame advance.
    public var elapsed: Double = 0

    public init(
        animations: [String: [String]],
        frameDuration: Double,
        defaultDirection: AnimationDirection = .down
    ) {
        self.animations    = animations
        self.frameDuration = frameDuration
        self.lastDirection = defaultDirection
        self.currentAnimation = "idle\(defaultDirection.rawValue)"
    }
}
