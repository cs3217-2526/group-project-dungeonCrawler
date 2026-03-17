//
//  ComponentStore.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

/// Type-erased protocol so ComponentStorage can hold stores of any T in one dictionary.
protocol AnyComponentStore {
    mutating func removeValue(for entityID: EntityID)
}

/// Concrete per-type store. Holds one [EntityID: T] dictionary.
struct ComponentStore<T: Component>: AnyComponentStore {

    private var _data: [EntityID: T] = [:]

    mutating func add(_ component: T, for entityID: EntityID) {
        _data[entityID] = component
    }

    func get(for entityID: EntityID) -> T? {
        _data[entityID]
    }

    mutating func modify(for entityID: EntityID, _ body: (inout T) -> Void) {
        guard _data[entityID] != nil else { return }
        body(&_data[entityID]!)
    }

    mutating func removeValue(for entityID: EntityID) {
        _data[entityID] = nil
    }

    var entities: [Entity] { _data.keys.map { Entity(id: $0) } }
}
