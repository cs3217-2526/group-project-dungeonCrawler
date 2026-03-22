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
| `SpriteComponent` | Texture, derived from `EnemyType` |
| `EnemyTagComponent` | Marks the entity as an enemy and stores its `EnemyType` |
| `VelocityComponent` | Movement vector, set each frame by `EnemyAISystem` |
| `EnemyStateComponent` | AI mode (wander/chase) and related configurations |
| `CollisionBoxComponent` | Axis-aligned bounding box, currently sized to `48 × 48 × scale` |

## Enemy Types

Enemy types are defined in the `EnemyType` enum. Each type maps to a texture asset and a scale multiplier.

**Current Enemy Types**:

| Type | Texture | Scale |
|---|---|---|
| .charger | "Charger" | 1.0 |
| .mummy | "Mummy" | 1.0 |
| .ranger | "Ranger" | 0.75 |
| .tower | "Tower" | 1.5 |


The final in-world scale is `baseScale × type.scale`, where `baseScale` is passed in at spawn time (derived from screen size — see [Map System](../room/mapSystem.md)).

## Spawning an Enemy

Use `EntityFactory.makeEnemy` to create an enemy entity:

```swift
EntityFactory.makeEnemy(in: world, at: position, type: .mummy)

// With a custom base scale
EntityFactory.makeEnemy(in: world, at: position, type: .tower, baseScale: 0.8)
```

In normal gameplay, enemies are spawned by `MapSystem` at the enemy spawn points generated for a room.

## Adding a New Enemy Type

1. **Add a case** to `EnemyType` in `EnemyTagComponent.swift`.
2. **Add a `textureName`** entry — add the corresponding asset to the asset catalog.
3. **Add a `scale`** entry — `1.0` is the baseline character size.

For example:
```swift
case goblin

var textureName: String {
    // ...
    case .goblin: return "Goblin"
}

var scale: Float {
    // ...
    case .goblin: return 0.85
}
```

No changes to `EntityFactory` or `EnemyAISystem` are needed. To give the new type different AI behaviour (e.g. faster chase speed), pass a custom `EnemyStateComponent` after creation:

For example:
```swift
let enemy = EntityFactory.makeEnemy(in: world, at: position, type: .goblin)
world.addComponent(
    component: EnemyStateComponent(detectionRadius: 200, chaseSpeed: 100),
    to: enemy
)
```

See [Enemy AI System](./enemyAISystem.md) for all configurable fields.
