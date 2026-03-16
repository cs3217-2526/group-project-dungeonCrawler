//
//  World.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

// Create one per game session; pass it everywhere.
public final class World {

    // MARK: - Subsystems (internal ownership)

    public let components = ComponentStorage()
    private var _entities: Set<Entity> = []

    // MARK: - Entity Lifecycle

    @discardableResult
    public func createEntity() -> Entity {
        let entity = Entity.init()
        _entities.insert(entity)
        return entity
    }

    public func destroyEntity(entity: Entity) {
        components.removeAll(from: entity)
        _entities.remove(entity)
    }
    
    public func destroyAllEntities() {
        for entity in _entities {
            components.removeAll(from: entity)
        }
        _entities.removeAll()
    }

    public func isAlive(entity: Entity) -> Bool {
        _entities.contains(entity)
    }

    public var allEntities: Set<Entity> { _entities }

    // MARK: - Component convenience pass-throughs

    public func addComponent<T: Component>(component: T, to entity: Entity) {
        components.add(component: component, to: entity)
    }

    public func getComponent<T: Component>(type: T.Type, for entity: Entity) -> T? {
        components.get(type: type, for: entity)
    }

    public func removeComponent<T: Component>(type: T.Type, from entity: Entity) {
        components.remove(type: type, from: entity)
    }
    
    public func modifyComponent<T: Component>(type: T.Type, for entity: Entity, body: (inout T) -> Void) {
        components.modify(type: type, for: entity, body: body)
    }

    // MARK: - Querying helpers used by Systems

    public func entities<T: Component>(with type: T.Type) -> [Entity] {
        components.entities(with: type)
    }

    /// Returns every living entity that has BOTH `T` and `U` (binary join).
    public func entities<T: Component, U: Component>(with typeA: T.Type, and typeB: U.Type) -> [(entity: Entity, a: T, b: U)] {
        entities(with: typeA).compactMap { entity in
            guard
                let a = components.get(type: typeA, for: entity),
                let b = components.get(type: typeB, for: entity)
            else { return nil }
            return (entity, a, b)
        }
    }
}
