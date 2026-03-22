---
title: "Collision System"
description: "How overlaps are detected, classified, and physically resolved."
---

# Collision System

`CollisionSystem` is the central hub of the collision module. It runs at priority 30 and is responsible for detecting overlaps between entities, classifying each pair, routing to the correct physics resolver, and flushing the destruction queue at the end of each frame.

## Responsibilities

| Responsibility | Method |
|---|---|
| Detect all overlaps this frame | `update(deltaTime:world:)` via `minimumTranslationVector()` |
| Classify each overlapping pair | `handleCollision()` |
| Resolve physics (push, knockback) | `resolveStaticCollision()`, `resolvePlayerEnemyCollision()`, `resolveEnemyEnemyCollision()` |
| Emit collision events for other systems | `CollisionEventBuffer.recordProjectileHitSolid()` |
| Flush deferred entity destruction | `DestructionQueue.flush(world:)` |

`CollisionSystem` does **not** destroy entities directly or apply damage. Those outcomes are handled by `ProjectileSystem` and a future `HealthSystem` via the `CollisionEventBuffer`.

## Initialisation

`CollisionSystem` requires two shared objects injected at construction time. Create them once per game session and pass the same instances into every system that needs them.

```swift
let events           = CollisionEventBuffer()
let destructionQueue = DestructionQueue()

let collisionSystem  = CollisionSystem(events: events, destructionQueue: destructionQueue)
let projectileSystem = ProjectileSystem(events: events, destructionQueue: destructionQueue)
```

## Update Loop

Each frame, `update(deltaTime:world:)` performs these steps in order:

1. **Clear the event buffer** — discards all events from the previous frame so consumers never see stale data.
2. **Query collidables** — fetches all entities that have both `TransformComponent` and `CollisionBoxComponent`.
3. **O(n²) overlap test** — each unique pair `(i, j)` where `j > i` is tested via `minimumTranslationVector()`. Non-overlapping pairs are skipped.
4. **Classify and route** — each overlapping pair is passed to `handleCollision()`.
5. **Flush destruction queue** — all entities enqueued during this frame (by any system) are destroyed.

## Collision Classification

`handleCollision()` inspects the component profile of each entity in an overlapping pair and routes to the correct resolver:

| Pair | Action |
|---|---|
| Projectile + solid (wall / obstacle) | Records `ProjectileHitSolidEvent` — no physics resolution |
| Projectile + projectile | Ignored |
| Projectile + non-solid | Ignored |
| Static + static | Ignored (neither entity can move) |
| Dynamic + static | `resolveStaticCollision` — only the dynamic entity is displaced by the full MTV |
| Player + enemy | `resolvePlayerEnemyCollision` — positional nudge on both + knockback on both |
| Enemy + enemy | `resolveEnemyEnemyCollision` — equal positional split, no knockback |

A **static** entity is one with no `VelocityComponent`. A **solid** entity is one tagged with `WallTag` or `ObstacleTag`. To register a new solid type, add one line to `isSolid()`:

```swift
private func isSolid(_ entity: Entity, world: World) -> Bool {
    world.getComponent(type: WallTag.self,     for: entity) != nil ||
    world.getComponent(type: ObstacleTag.self, for: entity) != nil
    // Add new solid tags here, e.g.:
    // || world.getComponent(type: ShieldTag.self, for: entity) != nil
}
```

## Physics Resolvers

### resolveStaticCollision

Called when a dynamic entity (player or enemy) overlaps a static entity (wall, obstacle). Only the dynamic entity moves — the static entity is never displaced. The dynamic entity is pushed by the full MTV.

### resolvePlayerEnemyCollision

Called when a player and an enemy overlap. Both entities are displaced: the player by a small fraction (`0.1 × MTV`), the enemy by a larger fraction (`0.75 × MTV`). Knockback is then applied to both via `applyKnockbackIfNeeded()` if they are not already under a knockback impulse.

```swift
let knockbackSpeed: Float    = 150   // units per second
let knockbackDuration: Float = 0.1   // seconds
```

### resolveEnemyEnemyCollision

Called when two enemies overlap. Each is displaced by half the MTV in opposite directions. No knockback is applied.

### applyKnockbackIfNeeded

The single entry point for adding a `KnockbackComponent`. It is a no-op if the entity already has one, preventing a new hit from cancelling active knockback mid-flight.

```swift
private func applyKnockbackIfNeeded(to entity: Entity, velocity: SIMD2<Float>,
                                     duration: Float, world: World) {
    guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { return }
    world.addComponent(component: KnockbackComponent(velocity: velocity, remainingTime: duration),
                       to: entity)
}
```

Call this from any new resolver that should produce knockback.

## SAT Implementation

Overlap detection uses the Separating Axis Theorem on four face-normal axes — the right and up vectors of each OBB after rotation. If any axis shows a gap between the two projected intervals, the boxes do not overlap and the function returns `nil`. Otherwise it returns the **minimum translation vector (MTV)**: the smallest displacement that separates the two boxes.

The MTV is always oriented from B toward A before being returned, so callers can apply it directly to push A away from B without recomputing direction.

---

## Common Extension Points

| Future feature | Where to make the change |
|---|---|
| Bullet damages enemy | Detect projectile + enemy in `handleCollision()`; add `ProjectileHitEnemyEvent`; handle in `HealthSystem` |
| Breakable wall | In the `ProjectileHitSolidEvent` handler, also enqueue `event.solid` for destruction |
| New solid surface | One line in `isSolid()` |
| Knockback from projectile impact | Call `applyKnockbackIfNeeded()` inside a new projectile-hit resolver |
| Player takes contact damage | Add `PlayerHitEnemyEvent`; handle in `HealthSystem` |