//
//  CollisionSystem.swift
//  dungeonCrawler
//
//  Created by Yu Letian on 16/3/26.
//

import Foundation
import simd

public final class CollisionSystem: System {
    public var dependencies: [System.Type] { [MovementSystem.self, HealthSystem.self] }
    
    public let events: CollisionEventBuffer
    public let destructionQueue: DestructionQueue
    
    public init(events: CollisionEventBuffer, destructionQueue: DestructionQueue) {
        self.events = events
        self.destructionQueue = destructionQueue
    }

    public func update(deltaTime: Double, world: World) {
        events.clear()
        
        // Need entities with BOTH Transform and CollisionBox components
        let collidables = world.entities(
            with: TransformComponent.self,
            and: CollisionBoxComponent.self
        )
        for i in 0..<collidables.count {
            let (entityA, transformA, boxA) = collidables[i]
            for j in (i + 1)..<collidables.count {
                let (entityB, transformB, boxB) = collidables[j]
                guard let mtv = minimumTranslationVector(
                    transformA: transformA, boxA: boxA,
                    transformB: transformB, boxB: boxB
                ) else { continue }
                
                // 2. Classify the pair and route to the correct handler.
                handleCollision(
                    entityA: entityA, transformA: transformA,
                    entityB: entityB, transformB: transformB,
                    mtv: mtv,
                    world: world
                )
            }
        }
        destructionQueue.flush(world: world)
    }
    
    private func handleCollision(
        entityA: Entity, transformA: TransformComponent,
        entityB: Entity, transformB: TransformComponent,
        mtv: SIMD2<Float>,
        world: World
    ) {
        let aIsProjectile = world.getComponent(type: ProjectileComponent.self, for: entityA) != nil
        let bIsProjectile = world.getComponent(type: ProjectileComponent.self, for: entityB) != nil
        let aIsSolid      = isSolid(entityA, world: world)
        let bIsSolid      = isSolid(entityB, world: world)
        let aIsEnemy      = isEnemy(entityA, world: world)
        let bIsEnemy      = isEnemy(entityB, world: world)
 
        // Projectile hits a solid surface — record event, skip physics resolution.
        if aIsProjectile && bIsSolid {
            events.recordProjectileHitSolid(projectile: entityA, solid: entityB)
            return
        }
        if bIsProjectile && aIsSolid {
            events.recordProjectileHitSolid(projectile: entityB, solid: entityA)
            return
        }
        
        // Projectile hits an enemy — record damage event, skip physics resolution.
        // CombatSystem consumes this to apply damage and destroy the projectile.
        if aIsProjectile && bIsEnemy {
            let damage = world.getComponent(type: ContactDamageComponent.self, for: entityA)?.damage ?? 0
            // Guard: a projectile should not damage its own owner
            let ownerID = world.getComponent(type: OwnerComponent.self, for: entityA)?.ownerEntity.id
            guard ownerID != entityB.id else { return }
            events.recordProjectileHitEnemy(projectile: entityA, enemy: entityB, damage: damage)
            return
        }
        if bIsProjectile && aIsEnemy {
            let damage = world.getComponent(type: ContactDamageComponent.self, for: entityB)?.damage ?? 0
            let ownerID = world.getComponent(type: OwnerComponent.self, for: entityB)?.ownerEntity.id
            guard ownerID != entityA.id else { return }
            events.recordProjectileHitEnemy(projectile: entityB, enemy: entityA, damage: damage)
            return
        }
 
        // Projectile↔projectile or projectile↔non-solid — ignore for now.
        // Add a ProjectileHitProjectileEvent here if you ever need it.
        if aIsProjectile || bIsProjectile { return }
 
        // Standard physics resolution for everything else.
        resolveCollision(
            entityA: entityA, entityB: entityB, mtv: mtv,
            transformA: transformA, transformB: transformB,
            world: world
        )
    }
 
    /// A solid entity is anything a projectile should stop on.
    /// Add new solid tags here as the game grows (e.g. ShieldTag).
    private func isSolid(_ entity: Entity, world: World) -> Bool {
        world.getComponent(type: WallTag.self,     for: entity) != nil ||
        world.getComponent(type: ObstacleTag.self, for: entity) != nil
    }
    
    /// An enemy is any entity tagged with EnemyTag.
    private func isEnemy(_ entity: Entity, world: World) -> Bool {
        world.getComponent(type: EnemyTagComponent.self, for: entity) != nil
    }

    /// Returns true if the two OBBs overlap.
    public func checkCollision(
        transformA: TransformComponent, boxA: CollisionBoxComponent,
        transformB: TransformComponent, boxB: CollisionBoxComponent
    ) -> Bool {
        minimumTranslationVector(transformA: transformA, boxA: boxA,
                                  transformB: transformB, boxB: boxB) != nil
    }

    /// Returns the MTV that separates A from B, or nil if they do not overlap.
    /// Uses SAT (Separating Axis Theorem) on the four OBB face-normal axes.
    private func minimumTranslationVector(
        transformA: TransformComponent, boxA: CollisionBoxComponent,
        transformB: TransformComponent, boxB: CollisionBoxComponent
    ) -> SIMD2<Float>? {
        let halfA = SIMD2<Float>(boxA.width / 2, boxA.height / 2)
        let halfB = SIMD2<Float>(boxB.width / 2, boxB.height / 2)

        // Face-normal axes for each OBB (right and up vectors after rotation).
        let axesA = obbAxes(rotation: transformA.rotation)
        let axesB = obbAxes(rotation: transformB.rotation)
        let axes: [SIMD2<Float>] = [axesA.0, axesA.1, axesB.0, axesB.1]

        var minOverlap = Float.infinity
        var mtvAxis   = SIMD2<Float>.zero

        for axis in axes {
            let projA = project(center: transformA.position, halfExtents: halfA, rotation: transformA.rotation, onto: axis)
            let projB = project(center: transformB.position, halfExtents: halfB, rotation: transformB.rotation, onto: axis)
            let o = min(projA.max, projB.max) - max(projA.min, projB.min)
            guard o > 0 else { return nil }  // Separating axis found, can be separated by a line
            if o < minOverlap {
                minOverlap = o
                mtvAxis = axis
            }
        }

        // Ensure MTV points from B toward A.
        if dot(transformA.position - transformB.position, mtvAxis) < 0 {
            mtvAxis = -mtvAxis
        }
        return mtvAxis * minOverlap
    }

    /// OBB helpers

    private func obbAxes(rotation: Float) -> (SIMD2<Float>, SIMD2<Float>) {
        (SIMD2<Float>(cos(rotation), sin(rotation)),
         SIMD2<Float>(-sin(rotation), cos(rotation)))
    }

    private func project(center: SIMD2<Float>, halfExtents: SIMD2<Float>, rotation: Float,
                         onto axis: SIMD2<Float>) -> (min: Float, max: Float) {
        let (right, up) = obbAxes(rotation: rotation)
        let r = abs(dot(right, axis)) * halfExtents.x + abs(dot(up, axis)) * halfExtents.y
        let c = dot(center, axis)
        return (c - r, c + r)
    }

    private func resolveCollision(entityA: Entity, entityB: Entity, mtv: SIMD2<Float>,
                                   transformA: TransformComponent, transformB: TransformComponent,
                                   world: World) {

        let aIsStatic = world.getComponent(type: VelocityComponent.self, for: entityA) == nil
        let bIsStatic = world.getComponent(type: VelocityComponent.self, for: entityB) == nil
        let aIsPlayer = world.getComponent(type: PlayerTagComponent.self, for: entityA) != nil
        let bIsPlayer = world.getComponent(type: PlayerTagComponent.self, for: entityB) != nil
        
        if aIsStatic && bIsStatic {
            return // Two static entities — nothing moves.
        } else if aIsStatic || bIsStatic {
            resolveStaticCollision(dynamic: aIsStatic ? entityB : entityA,
                                   mtv: aIsStatic ? -mtv : mtv,
                                   world: world)
        } else if aIsPlayer || bIsPlayer {
            let (player, enemy, pushTowardPlayer) = aIsPlayer
                ? (entityA, entityB,  mtv)
                : (entityB, entityA, -mtv)
            resolvePlayerEnemyCollision(player: player, enemy: enemy,
                                        pushTowardPlayer: pushTowardPlayer, world: world)
        } else {
            resolveEnemyEnemyCollision(entityA: entityA, entityB: entityB, mtv: mtv, world: world)
        }
    }
    
    /// Dynamic entity (player or enemy) hits a static entity (wall, obstacle).
    /// Only the dynamic entity is displaced; the static one never moves.
    private func resolveStaticCollision(dynamic: Entity, mtv: SIMD2<Float>, world: World) {
        world.modifyComponentIfExist(type: TransformComponent.self, for: dynamic) {
            $0.position += mtv
        }
    }

    /// Player and Enemy knockback are scaled inversely to their mass
    private func resolvePlayerEnemyCollision(player: Entity, enemy: Entity, pushTowardPlayer: SIMD2<Float>, world: World) {
        let baseKnockbackSpeed: Float = 1500
        let knockbackDuration: Float = 0.1
        let bounceDir = normalize(pushTowardPlayer)

        let rawEnemyMass = Float(world.getComponent(type: MassComponent.self, for: enemy)?.mass ?? 10)
        let rawPlayerMass = Float(world.getComponent(type: MassComponent.self, for: player)?.mass ?? 10)

        let enemyMass = max(rawEnemyMass, 1.0)
        let playerMass = max(rawPlayerMass, 1.0)
        let totalMass = enemyMass + playerMass

        let enemyKnockbackSpeed = baseKnockbackSpeed / enemyMass
        let playerKnockbackSpeed = baseKnockbackSpeed / playerMass

        world.modifyComponentIfExist(type: TransformComponent.self, for: player) {
            $0.position += pushTowardPlayer * (enemyMass / totalMass)
        }
        world.modifyComponentIfExist(type: TransformComponent.self, for: enemy) {
            $0.position -= pushTowardPlayer * (playerMass / totalMass)
        }
        applyKnockbackIfNeeded(to: player, velocity:  playerKnockbackSpeed * bounceDir,
                               duration: knockbackDuration, world: world)
        applyKnockbackIfNeeded(to: enemy,  velocity: -enemyKnockbackSpeed * bounceDir,
                               duration: knockbackDuration, world: world)
        let damage = world.getComponent(type: ContactDamageComponent.self, for: enemy)?.damage ?? 10.0
        events.recordPlayerHitByEnemy(player: player, enemy: enemy, damage: damage)
    }
 
    /// Two enemies overlap — equal positional split, no knockback.
    private func resolveEnemyEnemyCollision(entityA: Entity, entityB: Entity, mtv: SIMD2<Float>, world: World) {
        world.modifyComponentIfExist(type: TransformComponent.self, for: entityA) { $0.position += mtv * 0.5 }
        world.modifyComponentIfExist(type: TransformComponent.self, for: entityB) { $0.position -= mtv * 0.5 }
    }
 
    /// Adds a KnockbackComponent only if the entity is not already being knocked back.
    private func applyKnockbackIfNeeded(to entity: Entity, velocity: SIMD2<Float>, duration: Float, world: World) {
        guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { return }
        world.addComponent(
            component: KnockbackComponent(velocity: velocity, remainingTime: duration),
            to: entity
        )
    }
}
