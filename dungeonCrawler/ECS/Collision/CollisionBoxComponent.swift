//
//  CollisionBoxComponent.swift
//  dungeonCrawler
//
//  Created by Yu Letian on 16/3/26.
//
import simd

public struct CollisionBoxComponent: Component {
    public var size: SIMD2<Float>

    public var width: Float {
        size.x
    }

    public var height: Float {
        size.y
    }

    public init(size: SIMD2<Float> = .zero) {
        self.size = size
    }
}
