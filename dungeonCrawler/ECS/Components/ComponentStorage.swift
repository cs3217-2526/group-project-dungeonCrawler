//
//  ComponentStorage.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

public final class ComponentStorage {

    // MARK: - Internal layout
    /// [type key → [entity → component instance]]
    private var _storage: [ObjectIdentifier: [Entity: AnyObject]] = [:]

    // MARK: - Public API

    public func add<T: Component>(component: T, to entity: Entity) {
        let key = ObjectIdentifier(T.self)
        _storage[key, default: [:]][entity] = component
    }

    public func get<T: Component>(type: T.Type, for entity: Entity) -> T? {
        let key = ObjectIdentifier(T.self)
        return _storage[key]?[entity] as? T
    }

    public func remove<T: Component>(type: T.Type, from entity: Entity) {
        let key = ObjectIdentifier(T.self)
        _storage[key]?[entity] = nil
    }

    public func removeAll(from entity: Entity) {
        for key in _storage.keys {
            _storage[key]?[entity] = nil
        }
    }

    public func entities<T: Component>(with type: T.Type) -> [Entity] {
        let key = ObjectIdentifier(T.self)
        return Array(_storage[key]?.keys ?? [:].keys)
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
