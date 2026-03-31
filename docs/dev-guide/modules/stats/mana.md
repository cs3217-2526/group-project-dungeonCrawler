---
title: "Mana"
description: "How the mana pool works and how passive regeneration is driven by ManaSystem."
sidebar_position: 6
---

# Mana

The mana module manages the player's spell resource. It is composed of `ManaComponent`, which stores the mana pool, and `ManaSystem`, which handles passive regeneration each frame.

---

## ManaComponent

`ManaComponent` stores an entity's current, base, and maximum mana via `StatValue`, plus a regeneration rate. It conforms to `StatProvidable`.

```swift
public struct ManaComponent: StatProvidable {
    public var value: StatValue
    public var regenRate: Float  // mana per second

    public init(base: Float, max: Float, regenRate: Float = 0)
}
```

| Field | Description |
|---|---|
| `value.base` | Starting mana at initialisation |
| `value.current` | Live mana value, modified by spending and regeneration |
| `value.max` | Maximum mana ceiling |
| `regenRate` | Mana restored per second. `0` disables passive regeneration. |

**Example:**

```swift
// Player with 100 max mana, starts full, regenerates 5 mana/sec
world.addComponent(
    component: ManaComponent(base: 100, max: 100, regenRate: 5),
    to: player
)

// Entity with mana pool but no passive regen
world.addComponent(
    component: ManaComponent(base: 60, max: 60),
    to: entity
)
```

### Spending Mana

To consume mana (e.g. when casting a spell), decrement `value.current` directly:

```swift
world.modifyComponent(type: ManaComponent.self, for: player) { mana in
    mana.value.current -= spellCost
    mana.value.clampToMin()
}
```

To check whether the player can afford a spell before casting:

```swift
if let mana = world.getComponent(type: ManaComponent.self, for: player),
   mana.value.current >= spellCost {
    // proceed with cast
}
```

---

## ManaSystem

`ManaSystem` handles passive mana regeneration. It has no system dependencies and declares no priority, so it runs at the framework's default order.

Each frame, for every entity with a `ManaComponent`:

1. Skip if `regenRate` is `0` or below.
2. Skip if `value.current` is already at max (no wasted computation or floating-point drift).
3. Add `regenRate × deltaTime` to `value.current`.
4. Clamp `current` to `max` via `clampToMax()`.

```swift
// Effective regen per frame (at 60 fps, deltaTime ≈ 0.0167)
regenAmount = regenRate * Float(deltaTime)
```

`ManaSystem` only regenerates — it never spends mana. Spending is the responsibility of the system or logic that consumes it (e.g. a spell-casting system).

---

## Update Loop Summary

Each frame:

1. **`ManaSystem`** — for each entity with `ManaComponent` and `regenRate > 0`, tick `current` upward and clamp to `max`.
2. **Spell/ability system** (your implementation) — checks `current`, deducts cost, clamps to min.

---

## Configuring Mana for Different Entity Types

| Use case | Configuration |
|---|---|
| Player with slow regen | `ManaComponent(base: 100, max: 100, regenRate: 3)` |
| Player with fast regen | `ManaComponent(base: 100, max: 100, regenRate: 15)` |
| No passive regen (potion-only) | `ManaComponent(base: 100, max: 100)` — default `regenRate: 0` |
| Enemy with a mana pool | Same as above; `ManaSystem` processes any entity with the component |

---

## Dependencies

| Dependency | Role |
|---|---|
| `StatValue` | Underlying value type for `ManaComponent` |
| `ManaComponent` | Read and modified each frame for regen |

---