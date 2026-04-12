//
//  ChaseBehaviour.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation
import simd

/// Moves the entity directly toward the chase target (context.playerPos) at a fixed speed.
/// The chase target is whatever position the strategy supplies — typically the player,
/// but could be a taunt pet or any other point of interest in future.
public struct ChaseBehaviour: EnemyBehaviour {

    public var speed: Float

    public init(speed: Float = 70) {
        self.speed = speed
    }

    public func update(entity: Entity, context: BehaviourContext) {
        let delta = context.playerPos - context.transform.position
        guard simd_length_squared(delta) > 1e-6 else { return }

        context.world.getComponent(type: VelocityComponent.self, for: entity)?.linear = normalize(delta) * self.speed
    }
}
