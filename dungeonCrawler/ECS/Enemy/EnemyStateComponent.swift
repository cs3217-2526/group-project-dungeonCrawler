//
//  EnemyStateComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 17/3/26.
//

import Foundation
import simd

public enum EnemyMode {
    case wander
    case chase
}

public struct EnemyStateComponent: Component {
    public var mode: EnemyMode = .wander
    public var detectionRadius: Float
    public var loseRadius: Float
    public var wanderStrategy: any EnemyAIStrategy
    public var chaseStrategy: any EnemyAIStrategy

    public init(
        detectionRadius: Float = 150,
        loseRadius: Float = 225,
        wanderStrategy: any EnemyAIStrategy = WanderStrategy(),
        chaseStrategy: any EnemyAIStrategy = StraightLineChaseStrategy()
    ) {
        self.detectionRadius = detectionRadius
        self.loseRadius = loseRadius
        self.wanderStrategy = wanderStrategy
        self.chaseStrategy = chaseStrategy
    }
}
