//
//  EntityFactory.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

public enum EntityFactory {
    
    // MARK: - Player
    //
    // Components attached:
    //   • TransformComponent  — position, rotation, scale
    //   • VelocityComponent   — movement vector (starts at zero)
    //   • InputComponent      — intent from InputSystem
    //   • SpriteComponent     — visual representation
    //   • PlayerTag           — marks this as the human-controlled entity
    //   • HealthComponent        — current/max HP; entity destroyed at 0
    //   • MoveSpeedComponent     — scalar speed used by MovementSystem
    //   • CollisionBoxComponent  — axis-aligned bounding box for collision
    //
    // Future additions:
    //   • WeaponSlotComponent — which weapon is equipped
    //   • AnimationComponent  — walk / idle / attack animation state machine
    
    @discardableResult
    public static func makePlayer(
        in world: World,
        at position: SIMD2<Float>,
        textureName: String = "knight", // set to knight for now
        scale: Float = 1
    ) -> Entity {
        let entity = world.createEntity()
        
        world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: scale), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: InputComponent(), to: entity)
        world.addComponent(component: SpriteComponent(textureName: textureName), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        world.addComponent(component: CameraFocusComponent(), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        world.addComponent(component: ManaComponent(base: 100, max: 100), to: entity)
        world.addComponent(component: MoveSpeedComponent(base: 90), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2(48 * scale, 48 * scale)), to: entity)
        world.addComponent(component: FacingComponent(), to: entity)

        return entity
    }

    // MARK: - Enemy
    //
    // Components attached:
    //   • TransformComponent   — position, rotation, scale
    //   • SpriteComponent      — visual representation
    //   • EnemyTagComponent    — marks this as an enemy and holds its type
    //   • VelocityComponent    — movement vector (set each frame by EnemyAISystem)
    //   • EnemyStateComponent  — AI mode (wander/chase) and related config
    //   • CollisionBoxComponent  — axis-aligned bounding box for collision
    //
    // Future additions:
    //   • HealthComponent      — current / max health
    //   • CombatStatsComponent — attack damage, attack speed

    @discardableResult
    public static func makeEnemy(
        in world: World,
        at position: SIMD2<Float>,
        type: EnemyType,
        baseScale: Float = 1
    ) -> Entity {
        let entity = world.createEntity()
        let finalScale = baseScale * type.scale

        world.addComponent(component: TransformComponent(position: position, rotation: 0, scale: finalScale), to: entity)
        world.addComponent(component: SpriteComponent(textureName: type.textureName), to: entity)
        world.addComponent(component: EnemyTagComponent(enemyType: type), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyStateComponent(), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2(48 * finalScale, 48 * finalScale)), to: entity)

        return entity
    }
    
    // MARK: - Room Factory
        
    // Creates a room entity with all necessary components
    //
    // Components attached:
    //   • RoomComponent       — bounds, doorways, spawn points
    //   • TransformComponent  — position at room center (for spatial queries)
    //
    // Future additions:
    //   • RoomThemeComponent  — visual style (dungeon, forest, ice cave)
    //   • RoomLootComponent   — treasure chest spawn points
    
    @discardableResult
    public static func makeRoom(
        in world: World,
        bounds: RoomBounds,
        doorways: [Doorway] = [],
        spawnPoints: [SpawnPoint] = [],
        useGrid: Bool = false
    ) -> Entity {
        let entity = world.createEntity()
        var roomComponent = RoomComponent(bounds: bounds, doorways: doorways, spawnPoints: spawnPoints)
        
        // Optionally add grid layout for tile-based generation
        if useGrid {
            let gridSize = SIMD2<Int>(
                Int(bounds.size.x / 32), // 32 units per tile
                Int(bounds.size.y / 32)
            )
            roomComponent.gridLayout = GridLayout(gridSize: gridSize, cellSize: 32)
        }
        
        world.addComponent(component: roomComponent, to: entity)
        world.addComponent(component: TransformComponent(position: bounds.center), to: entity)
        return entity
    }


    @discardableResult
    public static func makeWeapon(
        in world: World,
        ownedBy player: Entity,
        textureName: String = "handgun",
        offset: SIMD2<Float> = .zero,
        scale: Float = 1,
        lastFiredAt: Float = 0
    ) -> Entity {
        let entity = world.createEntity()
        let startPos = world.getComponent(type: TransformComponent.self, for: player)?.position ?? .zero
        world.addComponent(component: TransformComponent(position: startPos + offset, rotation: 0, scale: scale), to: entity)
        let facingOfOwner = world.getComponent(type: FacingComponent.self, for: player)?.facing ?? .right
        world.addComponent(component: FacingComponent(facing: facingOfOwner), to: entity)
        world.addComponent(component: SpriteComponent(textureName: textureName, zPosition: 4), to: entity)
        world.addComponent(component: OwnerComponent(ownerEntity: player, offset: offset), to: entity)
        world.addComponent(component: WeaponComponent(
            type: .handgun,
            manaCost: 10,
            attackSpeed: 1,
            coolDownInterval: TimeInterval(0.2),
            lastFiredAt: lastFiredAt
        ), to: entity)
        return entity
    }
    
    @discardableResult
    public static func makeProjectile(
        from position: SIMD2<Float>,
        aimAt direction: SIMD2<Float>,
        speed: Float,
        effectiveRange: Float,
        owner: Entity,
        in world: World
    ) -> Entity {
        let entity = world.createEntity()
        let goingRight = direction.x >= 0
        let bulletRotation: Float = goingRight
            ? atan2(direction.y, direction.x)
            : -atan2(direction.y, -direction.x)
        world.addComponent(component: TransformComponent(position: position, rotation: bulletRotation, scale: 1), to: entity)
        world.addComponent(component: VelocityComponent(linear: direction * speed), to: entity)
        world.addComponent(component: SpriteComponent(textureName: "normalHandgunBullet", zPosition: 5), to: entity)
        world.addComponent(component: ProjectileComponent(damage: 10, owner: owner), to: entity)
        world.addComponent(component: EffectiveRangeComponent(base: effectiveRange), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: SIMD2<Float>(6, 6)), to: entity)
        return entity
    }
}
