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
    private var _entities: Set<EntityID> = []

    // MARK: - Entity Lifecycle

    @discardableResult
    public func createEntity() -> Entity {
        let entity = Entity.init()
        _entities.insert(entity.id)
        return entity
    }

    public func destroyEntity(entity: Entity) {
        components.removeAll(from: entity)
        _entities.remove(entity.id)
    }
    
    public func destroyAllEntities() {
        for entityID in _entities {
            let entity = Entity(id: entityID)
            components.removeAll(from: entity)
        }
        _entities.removeAll()
    }

    public func isAlive(entity: Entity) -> Bool {
        _entities.contains(entity.id)
    }

    public var allEntities: Set<Entity> {
        Set(_entities.map { Entity(id: $0) })
    }

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
    
    /// This method use closure `body` to modify component of type `T` in entity `entity`
    /// It will silently return if the component does not exist
    public func modifyComponentIfExist<T: Component>(type: T.Type, for entity: Entity, body: (inout T) -> Void) {
        components.modify(type: type, for: entity, body: body)
    }

    /// This method use closure `body` to modify component of type `T` in entity `entity`
    /// It will add a component of type `t`, i.e. the `component` in argument if the entity has no component of type `T`
    /// Practically, it means the `component` should be the desired result of applying the closure
    public func modifyComponent<T: Component>(type: T.Type, for entity: Entity, component: T?, body: (inout T) -> Void) {
        if components.get(type: type, for: entity) != nil {
            components.modify(type: type, for: entity, body: body)
        } else if let newComponent = component {
            components.add(component: newComponent, to: entity)
        }
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

    /// Returns every living entity that has all three of `T`, `U`, and `V` (3-way join).
    public func entities<T: Component, U: Component, V: Component>(
        with typeA: T.Type,
        and typeB: U.Type,
        and typeC: V.Type
    ) -> [(entity: Entity, a: T, b: U, c: V)] {
        components.entities(with: typeA).compactMap { entity in
            guard
                let a = components.get(type: typeA, for: entity),
                let b = components.get(type: typeB, for: entity),
                let c = components.get(type: typeC, for: entity)
            else { return nil }
            return (entity, a, b, c)
        }
    }

    /// Returns every living entity that has all three of `T`, `U`, `V` and `W` (4-way join).
    public func entities<T: Component, U: Component, V: Component, W: Component>(
        with typeA: T.Type,
        and typeB: U.Type,
        and typeC: V.Type,
        and typeD: W.Type
    ) -> [(entity: Entity, a: T, b: U, c: V, d: W)] {
        components.entities(with: typeA).compactMap { entity in
            guard
                let a = components.get(type: typeA, for: entity),
                let b = components.get(type: typeB, for: entity),
                let c = components.get(type: typeC, for: entity),
                let d = components.get(type: typeD, for: entity)
            else { return nil }
            return (entity, a, b, c, d)
        }
    }

    /// Returns every living entity that has all three of `T`, `U`, `V` and `W` and `Y` (5-way join).
    public func entities<T: Component, U: Component, V: Component, W: Component, Y: Component>(
        with typeA: T.Type,
        and typeB: U.Type,
        and typeC: V.Type,
        and typeD: W.Type,
        and typeE: Y.Type
    ) -> [(entity: Entity, a: T, b: U, c: V, d: W, e: Y)] {
        components.entities(with: typeA).compactMap { entity in
            guard
                let a = components.get(type: typeA, for: entity),
                let b = components.get(type: typeB, for: entity),
                let c = components.get(type: typeC, for: entity),
                let d = components.get(type: typeD, for: entity),
                let e = components.get(type: typeE, for: entity)
            else { return nil }
            return (entity, a, b, c, d, e)
        }
    }
}
