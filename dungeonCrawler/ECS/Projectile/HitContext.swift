//
//  HitContext.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation

protocol HitContext {
    var center: SIMD2<Float> { get set }
    var world: World { get }
}
