//
//  SpecialEffects.swift
//  dungeonCrawler
//
//  Created by Letian on 11/4/26.
//

import Foundation

class ZoneComponent: Component {
    var radius: Float
    var damagePerSecond: Float
    var duration: Float
    var elapsed: Float = 0
    
    init(radius: Float, damagePerSecond: Float, duration: Float, elapsed: Float) {
        self.radius = radius
        self.damagePerSecond = damagePerSecond
        self.duration = duration
        self.elapsed = elapsed
    }
}
