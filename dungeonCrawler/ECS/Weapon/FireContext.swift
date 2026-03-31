//
//  FireContext.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation

struct FireContext {
    let owner: Entity
    let weapon: Entity
    let fireDirection: SIMD2<Float>
    let spawnPosition: SIMD2<Float>
    let gameTime: Float
    let world: World
}
