//
//  WanderTargetComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 28/3/26.
//

import Foundation
import simd

/// Stores the current wander destination for an enemy using WanderStrategy.
/// Added lazily by WanderStrategy on first update — enemies that do not wander
/// (e.g. stationary tower) will never have this component.
public class WanderTargetComponent: Component {
    public var target: SIMD2<Float>?

    public init(target: SIMD2<Float>? = nil) {
        self.target = target
    }
}
