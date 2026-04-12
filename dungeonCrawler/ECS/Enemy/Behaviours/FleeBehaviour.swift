//
//  FleeBehaviour.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation
import simd

/// Moves the enemy directly away from the player at a fixed speed.
public struct FleeBehaviour: EnemyBehaviour {

    public var speed: Float

    public init(speed: Float = 90) {
        self.speed = speed
    }

    public func update(entity: Entity, context: BehaviourContext) {
        let delta = context.transform.position - context.playerPos
        guard simd_length_squared(delta) > 1e-6 else { return }

        context.world.getComponent(type: VelocityComponent.self, for: entity)?.linear = normalize(delta) * self.speed
    }
}
