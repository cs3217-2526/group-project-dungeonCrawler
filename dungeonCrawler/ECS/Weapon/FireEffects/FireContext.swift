//
//  FireContext.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation

public struct FireContext {
    let owner: Entity
    let weapon: Entity
    let fireDirection: SIMD2<Float>
    let firePosition: SIMD2<Float>
    let gameTime: Float
    let world: World
}
