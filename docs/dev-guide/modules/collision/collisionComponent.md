---
title: "Collision Components"
description: "Data types that describe collidable entities, knockback state, and collision events."
---

# Collision Components

Collision behaviour in the dungeon is driven by a small set of components and supporting types. These are the data layer — they hold state but contain no logic.

## CollisionBoxComponent

`CollisionBoxComponent` is the entry ticket into the collision pipeline. Any entity that should participate in collision detection must have both a `TransformComponent` and a `CollisionBoxComponent`.

```swift
public struct CollisionBoxComponent: Component {
    public var size: SIMD2<Float>   // Width (x) and height (y) of the box in world units
}
```

### Sizing Guidelines

| Entity type | Recommended size | Notes |
|---|---|---|
| Player | `SIMD2(48 * scale, 48 * scale)` | Matches sprite dimensions |
| Enemy | `SIMD2(48 * finalScale, 48 * finalScale)` | Set in `EntityFactory.makeEnemy` |
| Wall (horizontal) | `SIMD2(roomWidth - 2 * thickness, thickness)` | Set by `RoomGenerator` |
| Wall (vertical) | `SIMD2(thickness, roomHeight)` | Set by `RoomGenerator` |
| Projectile (handgun) | `SIMD2(6, 6)` | Will revisit and modify this to a relative value |

The projectile size should match the weapon's `bulletSize` field on `WeaponComponent` so collision box and visual stay consistent when new weapon types are added.

---

## CollisionEventBuffer

`CollisionEventBuffer` is a reference type that carries collision outcomes from `CollisionSystem` to any system that needs to react to them, within the same frame. It is created once per game session and injected into both `CollisionSystem` (writer) and consumer systems (read-only).

```swift
public final class CollisionEventBuffer {
    public private(set) var projectileHitSolid: [ProjectileHitSolidEvent]
    public func clear()
    public func recordProjectileHitSolid(projectile: Entity, solid: Entity)
}
```

The buffer is cleared at the top of every `CollisionSystem.update()` so consumers always see only this frame's events. Do not write to it from outside `CollisionSystem`.

### Current Event Types

| Struct | Fields | Consumed by |
|---|---|---|
| `ProjectileHitSolidEvent` | `projectile: Entity`, `solid: Entity` | `ProjectileSystem` — enqueues projectile for destruction |

### Adding a New Event Type

To add a `ProjectileHitEnemyEvent` for a future health system:

1. Add the struct to `CollisionEvents.swift`:

```swift
public struct ProjectileHitEnemyEvent {
    public let projectile: Entity
    public let enemy: Entity
    public let damage: Float
}
```

2. Add a `public private(set) var projectileHitEnemy: [ProjectileHitEnemyEvent] = []` property and a `recordProjectileHitEnemy()` method to `CollisionEventBuffer`.
3. Wipe the new array inside the existing `clear()` method.
4. In `CollisionSystem.handleCollision()`, detect the projectile + enemy pair and call `recordProjectileHitEnemy()`.

---

## DestructionQueue

`DestructionQueue` solves a specific problem: `World.destroyEntity()` is immediate, but systems need to mark entities for destruction while iterating over them. Calling `destroyEntity()` mid-loop mutates the underlying component stores and causes crashes or silently skipped entities.

```swift
public final class DestructionQueue {
    public func enqueue(_ entity: Entity)
    public func flush(world: World)
}
```

Systems call `enqueue()` during their update loop. `flush()` destroys all queued entities in one safe batch after all iteration is complete. `flush()` is idempotent — safe to call on an empty queue or more than once per frame.

### Flush Ownership

`CollisionSystem` calls `flush()` at the end of its `update()`. `ProjectileSystem` also calls `flush()` at the end of its `update()` so that projectile range expiry works correctly in isolation (e.g. unit tests where `CollisionSystem` is not running). The second flush in any given frame is always a no-op.

### Usage Pattern

```swift
// Inside any system — enqueue instead of destroying directly:
destructionQueue.enqueue(someEntity)

// flush() is called automatically at the end of CollisionSystem.update()
// and ProjectileSystem.update(). Do not call it from other systems.
```