//
//  FacingComponent.swift
//  dungeonCrawler
//
//  Created by Letian on 20/3/26.
//

import Foundation

public class FacingComponent: Component {
    public var facing: FacingType

    public init(facing: FacingType) {
        self.facing = facing
    }

    public init() {
        // force unwrap here is safe since the enum has at least one case,
        // as randomElement() only returns nil for empty collections.
        self.facing = FacingType.allCases.randomElement()!
    }
}

public enum FacingType: CaseIterable {
    case left
    case right
}
