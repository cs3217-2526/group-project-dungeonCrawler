import SpriteKit

/// Renders a health bar and mana bar as fixed-position HUD nodes inside `uiLayer`.
public final class SpriteKitHUDAdapter: HUDBackend {

    private let healthFill: SKSpriteNode
    private let manaFill: SKSpriteNode

    private static let barWidth: CGFloat  = 160
    private static let barHeight: CGFloat = 14
    private static let padding: CGFloat   = 20
    private static let gap: CGFloat       = 8

    public init(uiLayer: SKNode, screenSize: CGSize) {
        let leftEdge = -screenSize.width  / 2 + Self.padding
        let topY     =  screenSize.height / 2 - Self.padding - Self.barHeight / 2

        healthFill = Self.makeBar(
            in: uiLayer,
            color: SKColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1),
            leftEdge: leftEdge,
            centerY: topY
        )
        manaFill = Self.makeBar(
            in: uiLayer,
            color: SKColor(red: 0.15, green: 0.40, blue: 0.90, alpha: 1),
            leftEdge: leftEdge,
            centerY: topY - Self.barHeight - Self.gap
        )
    }

    // MARK: - HUDBackend
    public func updateHealthBar(current: Float, max: Float) {
        healthFill.xScale = ratio(current: current, max: max)
    }

    public func updateManaBar(current: Float, max: Float) {
        manaFill.xScale = ratio(current: current, max: max)
    }

    // MARK: - Helpers
    private func ratio(current: Float, max: Float) -> CGFloat {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(1, CGFloat(current / max)))
    }

    /// Builds a background and fill pair 
    /// Returns fill node for later manipulation.
    /// Fill is anchored at its left edge. `xScale` shrinks it rightward.
    private static func makeBar(
        in parent: SKNode,
        color: SKColor,
        leftEdge: CGFloat,
        centerY: CGFloat
    ) -> SKSpriteNode {
        // Background (slightly larger, semi-transparent dark)
        let bg = SKSpriteNode(
            color: SKColor(white: 0.05, alpha: 0.75),
            size: CGSize(width: barWidth + 4, height: barHeight + 4)
        )
        bg.anchorPoint = CGPoint(x: 0, y: 0.5)
        bg.position   = CGPoint(x: leftEdge - 2, y: centerY)
        bg.zPosition  = 50
        parent.addChild(bg)

        // Coloured fill — anchored left so xScale shrinks from the right
        let fill = SKSpriteNode(color: color, size: CGSize(width: barWidth, height: barHeight))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position    = CGPoint(x: leftEdge, y: centerY)
        fill.zPosition   = 51
        parent.addChild(fill)

        return fill
    }
}
