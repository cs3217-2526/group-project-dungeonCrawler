---
title: "Damage Module"
description: "How the damage module works, including contact damage, projectile hits, and invincibility frames."
---

# Damage Module

The damage module handles all health-reduction logic in the game. It is composed of three systems and components working together: **`DamageSystem`** applies damage from collisions each frame, and **`InvincibilitySystem`** ticks down and removes post-hit invincibility frames.

---

## Components

| Component | Role |
|---|---|
| `ContactDamageComponent` | Attached to enemies; defines how much damage they deal on contact with the player |
| `InvincibilityComponent` | Temporarily attached to the player after taking damage; prevents follow-up hits until it expires |

---

## Systems

### DamageSystem

`DamageSystem` runs at `priority: 40` and processes two categories of collision each frame, sourced from the `CollisionEventBuffer`:

| Event Buffer | Description |
|---|---|
| `projectileHitEnemy` | A player projectile overlapped an enemy |
| `playerHitByEnemy` | An enemy overlapped the player |

#### Projectile → Enemy

For each `projectileHitEnemy` event:

1. Skip if either entity is no longer alive.
2. Deduplicate — if the same projectile appears in multiple events this frame, damage is only applied **once**.
3. Subtract `event.damage` from the enemy's `HealthComponent`.
4. Enqueue the projectile for destruction via `DestructionQueue` (regardless of deduplication — all overlapping projectile events still destroy the projectile).

#### Enemy Contact → Player

For each `playerHitByEnemy` event:

1. Skip if the player entity is no longer alive.
2. Skip if the player currently has an `InvincibilityComponent` (they are in i-frames).
3. Subtract `event.damage` from the player's `HealthComponent`.
4. Attach an `InvincibilityComponent` to the player to prevent the next contact event from dealing damage immediately.

---

### InvincibilitySystem

`InvincibilitySystem` runs at `priority: 45` (after `DamageSystem`) and manages the lifespan of `InvincibilityComponent`.

Each frame, for every entity carrying an `InvincibilityComponent`:

1. Subtract `deltaTime` from `remainingTime`.
2. If `remainingTime` has reached zero or below, **remove** the component — the entity can take damage again.
3. Otherwise, write the updated `remainingTime` back to the component.

---

## Invincibility Frames (I-Frames)

After the player takes contact damage, an `InvincibilityComponent` is attached with a default duration of **0.5 seconds**. During this window, all `playerHitByEnemy` events are ignored by `DamageSystem`.

This prevents a single collision from draining multiple health points across consecutive frames while the physics contact persists.

```swift
// Default i-frame window applied by DamageSystem after a contact hit
InvincibilityComponent(remainingTime: 0.5)
```

To adjust the i-frame window, change the `remainingTime` passed in `DamageSystem.applyContactDamage()`.

---

## Update Loop Summary

Each frame, in system priority order:

1. **`DamageSystem` (priority 40)**
   - Reads `CollisionEventBuffer.projectileHitEnemy` → applies damage to enemies, destroys projectiles.
   - Reads `CollisionEventBuffer.playerHitByEnemy` → applies damage to player if not invincible, then grants i-frames.

2. **`InvincibilitySystem` (priority 45)**
   - Ticks down `InvincibilityComponent.remainingTime` on every entity that has one.
   - Removes the component once the timer expires.

---

## ContactDamageComponent

Attach this to any enemy entity to define how much damage it deals when it physically contacts the player. The value is read from the collision event — it is the responsibility of the collision detection layer to populate `event.damage` from this component.

```swift
public struct ContactDamageComponent: Component {
    public var damage: Float

    public init(damage: Float)
}
```

**Example — setting contact damage when creating an enemy:**

```swift
world.addComponent(
    component: ContactDamageComponent(damage: 15),
    to: enemy
)
```

---

## Adding Damage to a New Entity Type

### Enemy that deals contact damage

Add `ContactDamageComponent` to the entity at spawn time:

```swift
let enemy = EnemyEntityFactory(at: position, type: .charger, baseScale: scale).make(in: world)
world.addComponent(component: ContactDamageComponent(damage: 20), to: enemy)
```

### Projectile that damages enemies

Populate the `projectileHitEnemy` buffer in your collision detection code with the appropriate `damage` value. `DamageSystem` will handle the rest — no changes to the system are needed.

### Custom i-frame duration

If a specific entity type requires a longer or shorter invincibility window (e.g. a boss attack that should not grant i-frames, or a hazard with a shorter cooldown), attach `InvincibilityComponent` manually with a different `remainingTime` value immediately after applying damage:

```swift
// Short i-frame window for a hazard (0.2s instead of default 0.5s)
world.addComponent(component: InvincibilityComponent(remainingTime: 0.2), to: player)
```

---

## Dependencies

| Dependency | Role |
|---|---|
| `CollisionEventBuffer` | Source of `projectileHitEnemy` and `playerHitByEnemy` events |
| `DestructionQueue` | Receives projectiles to be destroyed after a hit |
| `HealthComponent` | Read and modified to apply damage |
| `InvincibilityComponent` | Checked by `DamageSystem`; managed by `InvincibilitySystem` |
| `KnockbackSystem` | `DamageSystem` has no direct dependency, but knockback is applied separately after damage |