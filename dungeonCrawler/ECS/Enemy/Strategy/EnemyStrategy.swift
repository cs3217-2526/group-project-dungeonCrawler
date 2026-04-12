//
//  EnemyStrategy.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 9/4/26.
//

import Foundation

/// The top-level decision-maker for an enemy.
/// A strategy receives a BehaviourContext each frame, decides which
/// EnemyBehaviour should run, handles the transition lifecycle
/// (onActivate / onDeactivate), and delegates execution to that behaviour.
public protocol EnemyStrategy {
    func update(entity: Entity, context: BehaviourContext)
}

public extension EnemyStrategy {
    /// Transitions to `behaviour` if it differs from the currently active one,
    /// firing onDeactivate on the old and onActivate on the new, then runs update.
    /// Call this from every concrete strategy's update instead of calling behaviour.update directly.
    ///
    /// - Parameters:
    ///   - behaviour: The behaviour to run this frame.
    ///   - allBehaviours: All behaviours owned by this strategy, used to look up the old one for onDeactivate.
    func activate(_ behaviour: any EnemyBehaviour,
                  from allBehaviours: [any EnemyBehaviour],
                  for entity: Entity,
                  context: BehaviourContext) {

        if context.world.getComponent(type: ActiveBehaviourComponent.self, for: entity) == nil {
            context.world.addComponent(component: ActiveBehaviourComponent(), to: entity)
        }

        let currentID = context.world.getComponent(type: ActiveBehaviourComponent.self,
                                                    for: entity)?.behaviourID

        // deactivate old behaviour and activate new one if current is different
        if currentID != behaviour.id {
            if let oldID = currentID,
               let old = allBehaviours.first(where: { $0.id == oldID }) {
                old.onDeactivate(entity: entity, context: context)
            }
            activateNewBehaviour(behaviour: behaviour, entity: entity, context: context)
        }

        behaviour.update(entity: entity, context: context)
    }


    func activateNewBehaviour(behaviour: any EnemyBehaviour,
                              entity: Entity,
                              context: BehaviourContext) {
        behaviour.onActivate(entity: entity, context: context)
        context.world.getComponent(type: ActiveBehaviourComponent.self, for: entity)?.behaviourID = behaviour.id
    }
}
