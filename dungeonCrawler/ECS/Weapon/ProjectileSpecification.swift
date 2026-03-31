//
//  ProjectileSpecification.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation

struct ProjectileSpec {
    let speed: Float
    let effectiveRange: Float
    let damage: Float
    let spriteName: String?
    let collisionSize: SIMD2<Float>?
}
