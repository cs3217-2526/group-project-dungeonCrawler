//
//  ShooterZigZagComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 2/4/26.
//

import Foundation

/// Tracks the current movement target for ShooterZigZagStrategy, expressed in polar
/// coordinates relative to the player so the target follows the player as they move.
public class ShooterBasicComponent: Component {
    /// Angle (radians) of the target relative to the player.
    public var targetAngle: Float?
    public var targetRadius: Float?

    public init() {}
}
