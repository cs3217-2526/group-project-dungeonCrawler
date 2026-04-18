//
//  BehaviourContext.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation
import simd

/// A snapshot of world state passed to every EnemyStrategy and EnemyBehaviour each frame.
/// Holds the raw data the system already has, plus convenience properties for the most
/// commonly needed derived values.
/// Behaviours that need anything else can query context.world directly or add an extension to Behaviour Context
public struct BehaviourContext {
    public let entity: Entity
    public let playerPos: SIMD2<Float>
    public let transform: TransformComponent
    public let world: World

    /// Euclidean distance from this enemy to the player this frame.
    public var distToPlayer: Float {
        simd_length(playerPos - transform.position)
    }

    /// Current HP as a fraction of max (0.0 – 1.0).
    /// Returns nil if the entity has no HealthComponent.
    public var healthFraction: Float? {
        guard let hp = world.getComponent(type: HealthComponent.self, for: entity) else { return nil }
        let maxHP = hp.value.max ?? hp.value.base
        guard maxHP > 0 else { return nil }
        return hp.value.current / maxHP
    }

    /// Speed multiplier from SlowComponent (0.0–1.0), or 1.0 if not slowed.
    public var slowMultiplier: Float {
        world.getComponent(type: SlowComponent.self, for: entity)?.multiplier ?? 1.0
    }

    /// The bounds of the room this entity belongs to, looked up via RoomMemberComponent → RoomMetadataComponent.
    /// Returns nil if the entity has no room membership or the room entity cannot be found.
    public var roomBounds: RoomBounds? {
        guard let roomMember = world.getComponent(type: RoomMemberComponent.self, for: entity) else { return nil }
        for roomEntity in world.entities(with: RoomMetadataComponent.self) {
            if let meta = world.getComponent(type: RoomMetadataComponent.self, for: roomEntity),
               meta.roomID == roomMember.roomID {
                return meta.bounds
            }
        }
        return nil
    }
}
