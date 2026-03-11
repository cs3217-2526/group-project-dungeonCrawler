//
//  Entity.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 10/3/26.
//

import Foundation

typealias EntityID = UUID

public struct Entity: Hashable, Equatable {
    let id: EntityID

    init(id: EntityID = UUID()) {
        self.id = id
    }
}
