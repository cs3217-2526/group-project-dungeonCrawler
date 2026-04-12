//
//  HitEffectsLibrary.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation

struct ZoneBase {
    let textureName: String
    let radius: Float
    let damagePerSecond: Float
    let duration: Float
    
}

enum HitEffectsLibrary {
    case fireZone
    var effectDefinition: ZoneBase {
        switch self {
        case .fireZone:
            ZoneBase(
                textureName: "firezone",
                radius: 200,
                damagePerSecond: 20,
                duration: 3)
        }
    }
}
