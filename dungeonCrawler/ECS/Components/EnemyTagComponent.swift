//
//  EnemyTagComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 16/3/26.
//

import Foundation

public enum EnemyType {
    case charger
    case mummy
    case ranger
    case tower

    var textureName: String {
        switch self {
        case .charger: return "Charger"
        case .mummy:   return "Mummy"
        case .ranger:  return "Ranger"
        case .tower:   return "Tower"
        }
    }

    var scale: Float {
        switch self {
        case .charger: return 1.0
        case .mummy:   return 1.0
        case .ranger:  return 0.75
        case .tower:   return 1.5
        }
    }
}

public struct EnemyTagComponent: Component {
    public let enemyType: EnemyType

    public init(enemyType: EnemyType) {
        self.enemyType = enemyType
    }
}
