---
title: "Knockback"
description: "How knockback is applied between player and enemy, and between enemies."
---

# Knockback

Knockback is a short timed impulse applied to an entity after a collision. It is represented by `KnockbackComponent` and driven by `KnockbackSystem`.

While a `KnockbackComponent` is present on an entity, several systems yield control to the impulse:

- `InputSystem` — skips the entity, so player input has no effect during knockback
- `MovementSystem` — skips the entity, so velocity-driven movement is suppressed
- `EnemyAISystem` — skips the entity, so AI-driven movement does not fight the impulse

---

## KnockbackComponent

```swift
public struct KnockbackComponent: Component {
    public var velocity: SIMD2<Float>  // Impulse direction and speed
    public var remainingTime: Float    // Seconds left on the impulse (default: 0.2)
}
```

The component is added by `CollisionSystem` and removed automatically by `KnockbackSystem` once `remainingTime` reaches zero.

---

## KnockbackSystem

`KnockbackSystem` runs at `priority: 12`. Lower priority numbers run first, so it runs before `EnemyAISystem` (15) and `MovementSystem` (20). Each frame it:

1. Applies `velocity × deltaTime` directly to `TransformComponent.position` for every entity with a `KnockbackComponent`.
2. Decrements `remainingTime` by `deltaTime`.
3. Removes the component once `remainingTime ≤ 0`.

The system moves entities directly via `TransformComponent` — it does **not** write to `VelocityComponent`.

---

## Player–Enemy Collision

When a player and enemy overlap, `CollisionSystem` does the following:

1. **Positional nudge** — the player is displaced by `0.1 × MTV`, the enemy by `0.75 × MTV` (normalised MTV). This separates them immediately.
2. **Knockback** — both entities receive a `KnockbackComponent` with:

| Field | Value |
|---|---|
| `velocity` | `normalise(MTV) × 150` (away from the other entity) |
| `remainingTime` | `0.1` seconds |

The player is knocked away from the enemy and the enemy away from the player simultaneously. Note that the enemy will get a bigger nudge compared to the player.

---

## Enemy–Enemy Collision

When two enemies overlap, `CollisionSystem` displaces each by half the MTV in opposite directions. **No knockback is applied** — enemies simply separate and resume normal AI movement on the next frame.

---

## Preventing Mid-Flight Cancellation

Knockback is only applied if the entity does not already have a `KnockbackComponent`. A second collision during an active knockback impulse is ignored:

```swift
private func applyKnockbackIfNeeded(to entity: Entity, velocity: SIMD2<Float>,
                                     duration: Float, world: World) {
    guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { return }
    world.addComponent(component: KnockbackComponent(velocity: velocity, remainingTime: duration),
                       to: entity)
}
```

This prevents rapid successive contacts from resetting or stacking the impulse.

---

## System Execution Order

Systems execute in ascending priority order (lower number = runs first).

| Priority | System | Role |
|---|---|---|
| `12` | `KnockbackSystem` | Applies and expires the impulse |
| `15` | `EnemyAISystem` | Skips enemies with `KnockbackComponent` |
| `20` | `MovementSystem` | Skips entities with `KnockbackComponent` |
| `30` | `CollisionSystem` | Detects overlaps, adds `KnockbackComponent` |

---

### Future Implementation:

We will introduce a mass component so that KnockbackComponent will determine the displacement based on the mass. (larger mass, smaller nudge)

