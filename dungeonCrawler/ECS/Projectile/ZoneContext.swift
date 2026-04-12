//
//  ZoneContext.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation

public struct ZoneContext: HitContext {
    var center: SIMD2<Float>
    let world: World
    let zoneBase: ZoneBase
}
