import SpriteKit

/// Renders a health bar and mana bar as fixed-position HUD nodes inside `uiLayer`.
public final class SpriteKitHUDAdapter: HUDBackend {

    private let healthFill: SKSpriteNode
    private let manaFill: SKSpriteNode

    private var ammoPips: [SKSpriteNode] = []
    private let ammoReloadFill: SKSpriteNode
    private let ammoReloadBg: SKSpriteNode
    private let ammoContainer: SKNode

    private let chargeFill: SKSpriteNode
    private let chargeBg: SKSpriteNode

    private static let barWidth: CGFloat  = 160
    private static let barHeight: CGFloat = 14
    private static let padding: CGFloat   = 20
    private static let gap: CGFloat       = 8

    private static let pipSize: CGFloat    = 8
    private static let pipSpacing: CGFloat = 4
    private static let ammoOffsetY: CGFloat = 34

    public init(uiLayer: SKNode, screenSize: CGSize) {
        let leftEdge = -screenSize.width  / 2 + Self.padding
        let topY     =  screenSize.height / 2 - Self.padding - Self.barHeight / 2

        (_, healthFill) = Self.makeBar(
            in: uiLayer,
            color: SKColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1),
            leftEdge: leftEdge,
            centerY: topY
        )
        (_, manaFill) = Self.makeBar(
            in: uiLayer,
            color: SKColor(red: 0.15, green: 0.40, blue: 0.90, alpha: 1),
            leftEdge: leftEdge,
            centerY: topY - Self.barHeight - Self.gap
        )

        let ammoUI = Self.makeAmmoBars(
            in: uiLayer,
            leftEdge: leftEdge,
            centerY: topY - 2 * (Self.barHeight + Self.gap)
        )

        ammoContainer  = ammoUI.container
        ammoReloadBg   = ammoUI.reloadBg
        ammoReloadFill = ammoUI.reloadFill

        (chargeBg, chargeFill) = Self.makeBar(
            in: uiLayer,
            color: SKColor(red: 1.00, green: 0.55, blue: 0.10, alpha: 1),
            leftEdge: leftEdge,
            centerY: topY - 3 * (Self.barHeight + Self.gap)
        )
        chargeBg.isHidden = true
        chargeFill.isHidden = true
    }

    // MARK: - HUDBackend

    public func updateHealthBar(current: Float, max: Float) {
        healthFill.xScale = ratio(current: current, max: max)
    }

    public func updateManaBar(current: Float, max: Float) {
        manaFill.xScale = ratio(current: current, max: max)
    }

    public func updateAmmoBar(current: Int, max: Int, isReloading: Bool, reloadProgress: Float) {
        ammoContainer.isHidden = false

        if isReloading {
            showReloadBar(progress: reloadProgress)
            ammoPips.forEach { $0.isHidden = true }
        } else {
            hideReloadBar()
            syncPips(current: current, max: max)
        }
    }

    public func hideAmmoBar() {
        ammoContainer.isHidden = true
    }

    public func updateChargeBar(progress: Float) {
        chargeBg.isHidden = false
        chargeFill.isHidden = false
        chargeFill.xScale = CGFloat(Swift.max(0, Swift.min(1, progress)))
    }

    public func hideChargeBar() {
        chargeBg.isHidden = true
        chargeFill.isHidden = true
    }

    // MARK: - Pips

    private func syncPips(current: Int, max: Int) {
        while ammoPips.count < max {
            let pip = makePip(index: ammoPips.count)
            ammoContainer.addChild(pip)
            ammoPips.append(pip)
        }

        while ammoPips.count > max {
            ammoPips.removeLast().removeFromParent()
        }

        for (index, pip) in ammoPips.enumerated() {
            pip.isHidden = false
            pip.color = index < current
                ? SKColor(white: 1.0, alpha: 0.95)
                : SKColor(white: 1.0, alpha: 0.20)
        }
    }

    private func makePip(index: Int) -> SKSpriteNode {
        let pip = SKSpriteNode(
            color: SKColor(white: 1.0, alpha: 0.95),
            size: CGSize(width: Self.pipSize, height: Self.pipSize)
        )
        pip.anchorPoint = CGPoint(x: 0, y: 0.5)
        pip.position    = CGPoint(x: CGFloat(index) * (Self.pipSize + Self.pipSpacing), y: 0)
        pip.zPosition   = 1
        return pip
    }

    // MARK: - Reload bar

    private func showReloadBar(progress: Float) {
        ammoReloadBg.isHidden   = false
        ammoReloadFill.isHidden = false
        ammoReloadFill.xScale   = CGFloat(max(0, min(1, progress)))
    }

    private func hideReloadBar() {
        ammoReloadBg.isHidden   = true
        ammoReloadFill.isHidden = true
    }

    // MARK: - Helpers

    private func ratio(current: Float, max: Float) -> CGFloat {
        guard max > 0 else { return 0 }
        return Swift.max(0, Swift.min(1, CGFloat(current / max)))
    }

    /// Builds a background + fill pair anchored at the left edge.
    /// `xScale` on the returned fill shrinks it rightward.
    @discardableResult
    private static func makeBar(
        in parent: SKNode,
        color: SKColor,
        leftEdge: CGFloat,
        centerY: CGFloat
    ) -> (bg: SKSpriteNode, fill: SKSpriteNode) {
        let bg = SKSpriteNode(
            color: SKColor(white: 0.05, alpha: 0.75),
            size: CGSize(width: barWidth + 4, height: barHeight + 4)
        )
        bg.anchorPoint = CGPoint(x: 0, y: 0.5)
        bg.position    = CGPoint(x: leftEdge - 2, y: centerY)
        bg.zPosition   = 50
        parent.addChild(bg)

        let fill = SKSpriteNode(color: color, size: CGSize(width: barWidth, height: barHeight))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position    = CGPoint(x: leftEdge, y: centerY)
        fill.zPosition   = 51
        parent.addChild(fill)

        return (bg, fill)
    }

    private static func makeAmmoBars(
        in parent: SKNode,
        leftEdge: CGFloat,
        centerY: CGFloat
    ) -> (container: SKNode, reloadBg: SKSpriteNode, reloadFill: SKSpriteNode) {
        let container = SKNode()
        container.position  = CGPoint(x: leftEdge, y: centerY)
        container.zPosition = 50
        container.isHidden  = true
        parent.addChild(container)

        // Reuse makeBar in local space (container already handles world positioning)
        let (reloadBg, reloadFill) = makeBar(
            in: container,
            color: SKColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1),
            leftEdge: 0,
            centerY: 0
        )
        reloadBg.isHidden   = true
        reloadFill.isHidden = true

        return (container, reloadBg, reloadFill)
    }
}
