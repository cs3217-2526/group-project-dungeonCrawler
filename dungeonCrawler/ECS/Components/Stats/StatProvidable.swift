//
//  StatProvidable.swift
//  dungeonCrawler
//
//  Created by gerteck on 3/17/26.
//

import Foundation

public protocol StatProvidable: Component {
    var value: StatValue { get set }
}
