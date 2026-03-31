//
//  EnemyAIStrategy.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 27/3/26.
//

import Foundation
import simd

public protocol EnemyAIStrategy {
    func update(entity: Entity,
                transform: TransformComponent,
                playerPos: SIMD2<Float>,
                world: World)
}
