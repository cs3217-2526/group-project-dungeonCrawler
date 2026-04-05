//
//  DestructionQueue.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 21/3/26.
//

import Foundation

public final class DestructionQueue {
    private var pending: Set<EntityID> = []
 
    /// Mark an entity for destruction at end-of-frame.
    public func enqueue(_ entity: Entity) {
        pending.insert(entity.id)
    }
 
    /// Destroy all queued entities and clear the queue.
    /// Call this once per frame after all systems have finished updating.
    public func flush(world: World) {
        for id in pending {
            let entity = Entity(id: id)
            guard world.isAlive(entity: entity) else { continue }
            world.destroyEntity(entity: entity)
        }
        pending.removeAll(keepingCapacity: true)
    }
}
