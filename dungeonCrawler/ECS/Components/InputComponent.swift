//
//  InputComponent.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

public struct InputComponent: Component {
    /// Normalised direction the player wants to move.
    public var moveDirection: SIMD2<Float>

    public var aimDirection: SIMD2<Float>

    public var isShooting: Bool

    public init(
        moveDirection: SIMD2<Float> = .zero,
        aimDirection:  SIMD2<Float> = .zero,
        isShooting: Bool = false
    ) {
        self.moveDirection = moveDirection
        self.aimDirection  = aimDirection
        self.isShooting    = isShooting
    }
}
