---
title: "Enemies"
description: "How enemies are structured, spawned, and how to add a new enemy type."
sidebar_position: 1
---

# Enemies

An enemy is an ECS entity created by `EntityFactory.makeEnemy`. Its behaviour is driven by `EnemyAISystem` in each frame.

## Components

Every enemy entity is created with the following components:

| Component | Role |
|---|---|
| `TransformComponent` | Position, rotation, and scale |
| `SpriteComponent` | Texture, derived from `EnemyType` at spawn time |
| `EnemyTagComponent` | Marks the entity as an enemy; holds the resolved `textureName` and `scale` |
| `VelocityComponent` | Movement vector, set each frame by `EnemyAISystem` |
| `EnemyStateComponent` | AI mode (wander/chase), detection radii, and strategy instances |
| `CollisionBoxComponent` | Axis-aligned bounding box, currently sized to `48 × 48 × scale` |

## Enemy Types

Enemy types are defined as static constants on the `EnemyType` struct in `ECS/Enemy/EnemyType.swift`. Each constant bundles all properties of that enemy in one place: texture, scale, mass, contact damage, and AI strategies.

**Current Enemy Types**:

| Type | Texture | Scale | Mass | Contact Damage | Wander Strategy | Chase Strategy |
|---|---|---|---|---|---|---|
| `.charger` | "Charger" | 1.0 | 15 | 20.0 | `WanderStrategy` | `StraightLineChaseStrategy` |
| `.mummy` | "Mummy" | 1.0 | 10 | 10.0 | `WanderStrategy` | `StraightLineChaseStrategy` |
| `.ranger` | "Ranger" | 0.75 | 5 | 5.0 | `WanderStrategy` | `ShooterBasicStrategy` |
| `.tower` | "Tower" | 1.5 | 20 | 15.0 | `StationaryStrategy` | `StationaryStrategy` |

The final in-world scale is `baseScale × type.scale`, where `baseScale` is passed in at spawn time (derived from screen size).

## Spawning an Enemy

Use `EnemyEntityFactory` to create an enemy entity:

```swift
EnemyEntityFactory(at: position, type: .mummy, baseScale: scale).make(in: world)

// baseScale defaults to 1 if omitted
EnemyEntityFactory(at: position, type: .tower).make(in: world)
```

In normal gameplay, enemies are spawned by `MapSystem` at the enemy spawn points generated for a room.

## Adding a New Enemy Type

Add a single `static let` block to `EnemyType.swift` — no other files need to change:

```swift
public static let goblin = EnemyType(
    textureName: "Goblin",
    scale: 0.85,
    mass: 8,
    contactDamage: 12.0,
    wanderStrategy: WanderStrategy(),
    chaseStrategy: StraightLineChaseStrategy()
)
```

Also add the corresponding texture asset to the asset catalog.

All properties are required by the compiler, so a new definition cannot be accidentally left incomplete.

No changes to `EnemyTagComponent` or `EnemyAISystem` are needed. To give the new type different AI behaviour, replace the `EnemyStateComponent` on the entity after creation using `world.addComponent` (which overwrites any existing component of the same type):

```swift
let enemy = EnemyEntityFactory(at: position, type: .goblin, baseScale: scale).make(in: world)
world.addComponent(
    component: EnemyStateComponent(
        detectionRadius: 200,
        loseRadius: 300,
        wanderStrategy: StationaryStrategy(),
        chaseStrategy: ShooterBasicStrategy(innerRadius: 120, outerRadius: 220)
    ),
    to: enemy
)
```

`EnemyStateComponent`'s initializer has defaults for all parameters (`detectionRadius: 150`, `loseRadius: 225`, `wanderStrategy: WanderStrategy()`, `chaseStrategy: StraightLineChaseStrategy()`), so you only need to supply the fields you want to override.

See [Enemy AI System](./enemyAISystem.md) for all available strategies and configurable fields.
