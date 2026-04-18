//
//  HitEffectsLibrary.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation

public struct ZoneBase {
    let textureName: String
    let radius: Float
    let damagePerSecond: Float
    let duration: Float
    
}

public enum HitEffectsLibrary {
    case fireZone
    public var effectDefinition: ZoneBase {
        switch self {
        case .fireZone:
            ZoneBase(
                textureName: "firearea",
                radius: 200,
                damagePerSecond: 20,
                duration: 3)
        }
    }
}
