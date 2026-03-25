//
//  KnockbackComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 19/3/26.
//

import Foundation
import simd

public struct KnockbackComponent: Component {
    public var velocity: SIMD2<Float>
    public var remainingTime: Float

    public init(velocity: SIMD2<Float>, remainingTime: Float = 0.2) {
        self.velocity = velocity
        self.remainingTime = remainingTime
    }
}
