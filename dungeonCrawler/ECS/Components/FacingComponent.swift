//
//  FacingComponent.swift
//  dungeonCrawler
//
//  Created by Letian on 20/3/26.
//

import Foundation
import simd

public class FacingComponent: Component {
    public var facing: AnimationDirection

    public init(facing: AnimationDirection) {
        self.facing = facing
    }

    public init() {
        // force unwrap here is safe since the enum has at least one case,
        // as randomElement() only returns nil for empty collections.
        self.facing = AnimationDirection.allCases.randomElement()!
    }
}
