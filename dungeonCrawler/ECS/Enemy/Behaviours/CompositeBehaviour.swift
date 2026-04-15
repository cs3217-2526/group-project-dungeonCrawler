//
//  CompositeBehaviour.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 14/4/26.
//

import Foundation
 
/// Combines two behaviours into one, delegating lifecycle and update to both.
/// Useful for pairing a movement behaviour with an attack behaviour in a
/// single strategy slot — e.g. OrbitBehaviour + ShooterBehaviour as one attackBehaviour.
///
/// id is derived from both children so ActiveBehaviourComponent tracks the
/// pair as a single unit, and transitions fire correctly.
public struct CompositeBehaviour: EnemyBehaviour {
 
    public let primary: any EnemyBehaviour
    public let secondary: any EnemyBehaviour
 
    public var id: String { "\(primary.id)+\(secondary.id)" }
 
    public init(_ primary: any EnemyBehaviour, _ secondary: any EnemyBehaviour) {
        self.primary = primary
        self.secondary = secondary
    }
 
    public func onActivate(entity: Entity, context: BehaviourContext) {
        primary.onActivate(entity: entity, context: context)
        secondary.onActivate(entity: entity, context: context)
    }
 
    public func onDeactivate(entity: Entity, context: BehaviourContext) {
        primary.onDeactivate(entity: entity, context: context)
        secondary.onDeactivate(entity: entity, context: context)
    }
 
    public func update(entity: Entity, context: BehaviourContext) {
        primary.update(entity: entity, context: context)
        secondary.update(entity: entity, context: context)
    }
}
