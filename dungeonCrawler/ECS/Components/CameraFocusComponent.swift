//
//  CameraFocusComponent.swift
//  dungeonCrawler
//
//
//  Created by gerteck on 17/3/26.
//

import Foundation
import simd

/// Marks an entity as the subject the camera should follow.
/// Only one entity should carry this component at a time.
public struct CameraFocusComponent: Component {
    /// Optional world-space offset applied on top of the entity's position.
    public var lookOffset: SIMD2<Float>

    public init(lookOffset: SIMD2<Float> = .zero) {
        self.lookOffset = lookOffset
    }
}
