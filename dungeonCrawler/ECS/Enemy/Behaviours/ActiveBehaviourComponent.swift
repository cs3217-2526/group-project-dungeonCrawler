//
//  ActiveBehaviourComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation

/// Tracks which behaviour is currently running on an enemy entity.
/// Stored on the entity so the strategy can detect transitions and
/// fire onActivate / onDeactivate at the right moment.
/// Added lazily by the strategy on first update.
public class ActiveBehaviourComponent: Component {
    /// The id of the currently active EnemyBehaviour, or nil if none
    public var behaviourID: String?

    public init(behaviourID: String? = nil) {
        self.behaviourID = behaviourID
    }
}
