//
//  EnemyEntityFactory.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 24/3/26.
//

import Foundation
import simd

// new enemy types should go in here
public enum EnemyType {
    case charger
    case mummy
    case ranger
    case tower

    var textureName: String {
        switch self {
        case .charger: return "Charger"
        case .mummy:   return "Mummy"
        case .ranger:  return "Ranger"
        case .tower:   return "Tower"
        }
    }

    var scale: Float {
        switch self {
        case .charger: return 1.0
        case .mummy:   return 1.0
        case .ranger:  return 0.75
        case .tower:   return 1.5
        }
    }

    var mass: Int {
        switch self {
        case .charger: return 15
        case .mummy:   return 10
        case .ranger:  return 5
        case .tower:   return 20
        }
    }
    
    var contactDamage: Float {
        switch self {
        case .charger: return 20.0
        case .mummy:   return 10.0
        case .ranger:  return 5.0
        case .tower:   return 15.0
        }
    }

    var wanderStrategy: any EnemyAIStrategy {
        switch self {
        case .charger: return WanderStrategy()
        case .mummy:   return WanderStrategy()
        case .ranger:  return WanderStrategy()
        case .tower:   return StationaryStrategy()
        }
    }

    var chaseStrategy: any EnemyAIStrategy {
        switch self {
        case .charger: return StraightLineChaseStrategy()
        case .mummy:   return StraightLineChaseStrategy()
        case .ranger:  return ShooterBasicStrategy()
        case .tower:   return StationaryStrategy()
        }
    }
}

// Components attached:
//   • TransformComponent     — position, rotation, scale
//   • SpriteComponent        — visual representation
//   • EnemyTagComponent      — marks this as an enemy and holds its type
//   • VelocityComponent      — movement vector (set each frame by EnemyAISystem)
//   • EnemyStateComponent    — AI mode (wander/chase) and related config
//   • CollisionBoxComponent  — axis-aligned bounding box for collision
//   • MassComponent          — current mass used by KnockbackSystem
//   • HealthComponent        — current / max health
//   • ContactDamageComponent — attack damage
//
// Future additions:
//   • CombatStatsComponent   — attack damage, attack speed

public struct EnemyEntityFactory: EntityFactory {
    let position: SIMD2<Float>
    let type: EnemyType
    let baseScale: Float

    public init(
        at position: SIMD2<Float>,
        type: EnemyType,
        baseScale: Float = 1
    ) {
        self.position = position
        self.type = type
        self.baseScale = baseScale
    }

    @discardableResult
    public func make(in world: World) -> Entity {
        let entity = world.createEntity()
        let finalScale = baseScale * type.scale

        world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: finalScale), to: entity)
        world.addComponent(component: SpriteComponent(
            content: .texture(name: type.textureName),
            layer: .entity
        ), to: entity)

        world.addComponent(component: EnemyTagComponent(
            textureName: type.textureName,
            scale: finalScale
        ), to: entity)
        
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyStateComponent(
            wanderStrategy: type.wanderStrategy,
            chaseStrategy: type.chaseStrategy
        ), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2(WorldConstants.playerSize * finalScale, WorldConstants.playerSize * finalScale)), to: entity)
        world.addComponent(component: MassComponent(mass: type.mass), to: entity)
        world.addComponent(component: ContactDamageComponent(damage: type.contactDamage), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)

        return entity
    }
}
