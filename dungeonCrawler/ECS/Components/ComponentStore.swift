//
//  ComponentStore.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

/// Type-erased protocol so ComponentStorage can hold stores of any T in one dictionary.
protocol AnyComponentStore {
    mutating func removeValue(for entity: Entity)
}

/// Concrete per-type store. Holds one [Entity: T] dictionary.
struct ComponentStore<T: Component>: AnyComponentStore {

    private var _data: [Entity: T] = [:]

    mutating func add(_ component: T, for entity: Entity) {
        _data[entity] = component
    }

    func get(for entity: Entity) -> T? {
        _data[entity]
    }

    mutating func modify(for entity: Entity, _ body: (inout T) -> Void) {
        guard _data[entity] != nil else { return }
        body(&_data[entity]!)
    }

    mutating func removeValue(for entity: Entity) {
        _data[entity] = nil
    }

    var entities: [Entity] { Array(_data.keys) }
}
