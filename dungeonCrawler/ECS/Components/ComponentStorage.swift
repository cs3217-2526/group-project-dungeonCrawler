//
//  ComponentStorage.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

public final class ComponentStorage {

    // MARK: - Internal layout
    private var _stores: [ObjectIdentifier: any AnyComponentStore] = [:]
    
    // MARK: - Private store access

    /// Returns the existing ComponentStore<T> for type T, or creates a new empty one.
    private func store<T: Component>(for type: T.Type) -> ComponentStore<T> {
        let key = ObjectIdentifier(T.self)
        return (_stores[key] as? ComponentStore<T>) ?? ComponentStore<T>()
    }

    /// Writes a (possibly mutated) ComponentStore<T> back into the registry.
    private func setStore<T: Component>(_ store: ComponentStore<T>, for type: T.Type) {
        _stores[ObjectIdentifier(T.self)] = store
    }


    // MARK: - Public API

    public func add<T: Component>(component: T, to entity: Entity) {
        var s = store(for: T.self)
        s.add(component, for: entity.id)
        setStore(s, for: T.self)
    }

    func get<T: Component>(type: T.Type, for entity: Entity) -> T? {
        store(for: type).get(for: entity.id)
    }
    
    public func modify<T: Component>(type: T.Type, for entity: Entity, body: (inout T) -> Void) {
        var s = store(for: type)
        s.modify(for: entity.id, body)
        setStore(s, for: type)
    }

    public func remove<T: Component>(type: T.Type, from entity: Entity) {
        var s = store(for: type)
        s.removeValue(for: entity.id)
        setStore(s, for: type)
    }

    public func removeAll(from entity: Entity) {
        for key in _stores.keys {
            _stores[key]!.removeValue(for: entity.id)
        }
    }

    public func entities<T: Component>(with type: T.Type) -> [Entity] {
        store(for: type).entities
    }

    // MARK: - Subscript sugar

    public subscript<T: Component>(entity: Entity, type: T.Type) -> T? {
        get { get(type: type, for: entity) }
        set {
            if let value = newValue {
                add(component: value, to: entity)
            } else {
                remove(type: type, from: entity)
            }
        }
    }
}
