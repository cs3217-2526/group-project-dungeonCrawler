//
//  VelocityComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

public class VelocityComponent: Component {
    /// Desired movement vector in world-space points-per-second.
    public var linear: SIMD2<Float>

    /// Angular velocity in radians per second (used by homing projectiles, etc).
    public var angular: Float

    public init(linear: SIMD2<Float> = .zero, angular: Float = 0) {
        self.linear = linear
        self.angular = angular
    }
}
