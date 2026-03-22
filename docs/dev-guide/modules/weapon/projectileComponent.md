---
title: "Projectile Component"
description: "How projectile entities are created and managed."
sidebar_position: 3
---

# Projectile Component

`ProjectileComponent` marks an entity as a projectile and stores its damage value and the entity that fired it.

## ProjectileComponent

```swift
struct ProjectileComponent: Component {
    var damage: Float
    var owner: Entity
}
```

| Property | Type | Description |
|---|---|---|
| `damage` | `Float` | Hit-point damage dealt on impact |
| `owner` | `Entity` | The entity that fired this projectile (used to avoid self-damage) |

## Creating a Projectile Entity

Projectiles are created via `EntityFactory.makeProjectile`:

```swift
EntityFactory.makeProjectile(
    from: ownerTransform.position,
    aimAt: fireDirection,
    speed: speedWhenFired,
    owner: ownerEntity,
    in: world
)
```

These components attache to the new entity (the projectile):

| Component | Value |
|---|---|
| `TransformComponent` | Spawns at the given position; rotation derived from direction |
| `VelocityComponent` | `direction * speed` |
| `SpriteComponent` | `"normalHandgunBullet"`, z-position 5 |
| `ProjectileComponent` | `damage in factory method: 10`, `owner: ownerEntity` |
| `EffectiveRangeComponent` | `base in factory method: 400` units |
| `CollisionBoxComponent` | 6 × 6 point hitbox |

## Lifetime

A projectile is destroyed when either:

1. **Range is exhausted** — `EffectiveRangeComponent.value.current` reaches 0 (base range: 400 units).
2. **It hits a solid** — the `CollisionEventBuffer` emits a `projectileHitSolid` event for it.

Both cases enqueue the entity in `DestructionQueue`, which flushes at the end of `ProjectileSystem.update`.

*In future iterations, we want to add a third case for hitting a damageable entity (e.g. an enemy), but currently projectiles pass through enemies without collision.*

## ProjectileSystem

`ProjectileSystem` runs at `priority: 60` — after `WeaponSystem` (priority 50) so any newly spawned projectiles are already in the world when movement is applied.

Each frame it:
1. Moves every projectile by `velocity × deltaTime`.
2. Decrements `EffectiveRangeComponent` by the distance traveled; enqueues expired projectiles.
3. Reads `CollisionEventBuffer.projectileHitSolid` and enqueues all hit projectiles.
4. Flushes `DestructionQueue`.

## Dependencies

| Dependency | Role |
|---|---|
| `VelocityComponent` | Stores the projectile's linear velocity vector |
| `EffectiveRangeComponent` | Tracks remaining travel distance before auto-destruction |
| `CollisionBoxComponent` | Defines the hitbox for wall/solid collision detection |
| `CollisionEventBuffer` | Source of `projectileHitSolid` events |
| `DestructionQueue` | Deferred entity removal to avoid mutating the world mid-iteration |
| `EntityFactory` | Factory method for creating projectile entities |
