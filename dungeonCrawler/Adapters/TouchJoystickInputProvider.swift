//
//  TouchJoystickInputProvider.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd
import UIKit

public final class TouchJoystickInputProvider: InputProvider {

    // MARK: - Configuration

    public var joystickRadius: Float = 50
    public var deadZone: Float = 10
    public var leftZoneFraction: CGFloat = 0.5
    public var shootThreshold: Float = 0.25

    // MARK: - Joystick visual state (read by GameScene to draw the HUD)

    /// Where the left joystick base is currently anchored (floating origin).
    /// nil when the left thumb is not touching.
    public private(set) var leftBasePosition:    CGPoint? = nil
    public private(set) var leftHandlePosition:  CGPoint? = nil
    public private(set) var rightBasePosition:   CGPoint? = nil
    public private(set) var rightHandlePosition: CGPoint? = nil

    // MARK: - InputProvider

    public var rawMoveVector: SIMD2<Float> { quantise(deflection(for: _leftStick)) }
    public var rawAimVector:  SIMD2<Float> { quantise(deflection(for: _rightStick)) }
    public var isShootPressed: Bool {
        length(deflection(for: _rightStick)) / joystickRadius > shootThreshold
    }

    // MARK: - Internal state

    private struct StickState {
        weak var touch: UITouch?
        var origin:  CGPoint = .zero
        var current: CGPoint = .zero
        var isActive: Bool { touch != nil }
    }

    private var _leftStick  = StickState()
    private var _rightStick = StickState()

    public init() {}

    // MARK: - Touch forwarding

    public func touchesBegan(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            let pos = touch.location(in: view)
            if pos.x < view.bounds.width * leftZoneFraction {
                if !_leftStick.isActive {
                    _leftStick = StickState(touch: touch, origin: pos, current: pos)
                    leftBasePosition   = pos
                    leftHandlePosition = pos
                }
            } else {
                if !_rightStick.isActive {
                    _rightStick = StickState(touch: touch, origin: pos, current: pos)
                    rightBasePosition   = pos
                    rightHandlePosition = pos
                }
            }
        }
    }

    public func touchesMoved(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            if touch === _leftStick.touch {
                _leftStick.current = touch.location(in: view)
                leftHandlePosition = clampedHandlePosition(
                    origin: _leftStick.origin,
                    current: _leftStick.current
                )
            }
            if touch === _rightStick.touch {
                _rightStick.current = touch.location(in: view)
                rightHandlePosition = clampedHandlePosition(
                    origin: _rightStick.origin,
                    current: _rightStick.current
                )
            }
        }
    }

    public func touchesEnded(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            if touch === _leftStick.touch {
                _leftStick = StickState()
                leftBasePosition   = nil
                leftHandlePosition = nil
            }
            if touch === _rightStick.touch {
                _rightStick = StickState()
                rightBasePosition   = nil
                rightHandlePosition = nil
            }
        }
    }

    public func touchesCancelled(_ touches: Set<UITouch>, in view: UIView) {
        touchesEnded(touches, in: view)
    }

    // MARK: - Geometry

    private func deflection(for stick: StickState) -> SIMD2<Float> {
        guard stick.isActive else { return .zero }
        let dx =  Float(stick.current.x - stick.origin.x)
        let dy = -Float(stick.current.y - stick.origin.y)  // UIKit y-down → SpriteKit y-up
        let vec = SIMD2<Float>(dx, dy)
        guard length(vec) >= deadZone else { return .zero }
        return length(vec) > joystickRadius ? normalize(vec) * joystickRadius : vec
    }

    /// Snap continuous angle to nearest 45° and return a unit vector.
    private func quantise(_ vec: SIMD2<Float>) -> SIMD2<Float> {
        guard length(vec) > 0.001 else { return .zero }
        let angle   = atan2(vec.y, vec.x)
        let step    = Float.pi / 4
        let snapped = (angle / step).rounded() * step
        let result  = SIMD2<Float>(cos(snapped), sin(snapped))
        return SIMD2<Float>(
            abs(result.x) < 1e-6 ? 0 : result.x,
            abs(result.y) < 1e-6 ? 0 : result.y
        )
    }

    /// UIKit-space handle position, clamped to joystickRadius for drawing.
    private func clampedHandlePosition(origin: CGPoint, current: CGPoint) -> CGPoint {
        let dx = current.x - origin.x
        let dy = current.y - origin.y
        let dist = hypot(dx, dy)
        let radius = CGFloat(joystickRadius)
        if dist <= radius { return current }
        let scale = radius / dist
        return CGPoint(x: origin.x + dx * scale, y: origin.y + dy * scale)
    }
}

// MARK: - MockInputProvider  (unit tests / CI — no UIKit dependency)

public final class MockInputProvider: InputProvider {
    public var rawMoveVector: SIMD2<Float> = .zero
    public var rawAimVector:  SIMD2<Float> = .zero
    public var isShootPressed: Bool = false
    public init() {}
}
