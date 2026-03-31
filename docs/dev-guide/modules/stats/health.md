---
title: "Health"
description: "How health is stored, how death is detected, and how the player death event works."
sidebar_position: 5
---

# Health

The health module tracks hit points for every entity that can be damaged or destroyed. It is composed of `HealthComponent`, `HealthSystem`, and `PlayerDeathEvent`.

For how damage is applied to `HealthComponent`, see [Damage Module](./damage.md).

---

## HealthComponent

`HealthComponent` stores an entity's current, base, and maximum HP via `StatValue`. It conforms to `StatProvidable`.

```swift
public struct HealthComponent: StatProvidable {
    public var value: StatValue

    // Starting HP equals max HP
    public init(base: Float)

    // Starting HP is different from max HP
    public init(base: Float, max: Float)
}
```

Use the single-argument initialiser for most entities where the entity starts at full health. Use the two-argument form when an entity should spawn with reduced HP.

**Example:**

```swift
// Enemy that starts at full HP
world.addComponent(component: HealthComponent(base: 80), to: enemy)

// Player that starts at 50 of a 100 max (e.g. after a room transition penalty)
world.addComponent(component: HealthComponent(base: 50, max: 100), to: player)
```

Damage is applied by directly decrementing `value.current` and calling `clampToMin()`:

```swift
world.modifyComponent(type: HealthComponent.self, for: entity) { health in
    health.value.current -= damage
    health.value.clampToMin()
}
```

---

## HealthSystem

`HealthSystem` runs after `EnemyAISystem` and scans every entity with a `HealthComponent` each frame. Its only job is zero-HP detection — it does not apply damage itself.

For each entity with `HealthComponent`:

1. Skip if `value.current > 0`.
2. If the entity has `PlayerTagComponent` → call `playerDeathEvent.record()`. The player entity is **not** destroyed here, so other systems can finish processing the current frame safely.
3. Otherwise → enqueue the entity for destruction via `DestructionQueue`.

```swift
public final class HealthSystem: System {
    public var dependencies: [System.Type] { [EnemyAISystem.self] }
    // ...
}
```

---

## PlayerDeathEvent

`PlayerDeathEvent` is a simple flag object written by `HealthSystem` and read by `GameScene` after each frame's system update loop completes.

```swift
public final class PlayerDeathEvent {
    public private(set) var playerDied: Bool = false

    public func record()  // called by HealthSystem
    public func reset()   // called by GameScene on restart
}
```

**Lifecycle:**

1. `HealthSystem` calls `record()` when the player's HP hits zero.
2. After the update loop, `GameScene` checks `playerDied` and triggers game over if `true`.
3. On game restart, `GameScene` calls `reset()` to clear the flag.

`GameScene` is the sole consumer. Do not call `reset()` from within the ECS update loop.

---

## Death Handling Summary

| Entity type | Action when HP ≤ 0 |
|---|---|
| Enemy / non-player | Added to `DestructionQueue`, removed next frame |
| Player | `PlayerDeathEvent.record()` called; entity persists until `GameScene` handles game over |

---

## Dependencies

| Dependency | Role |
|---|---|
| `StatValue` | Underlying value type for `HealthComponent` |
| `DestructionQueue` | Receives non-player entities for removal |
| `PlayerDeathEvent` | Signals `GameScene` that the player has died |
| `PlayerTagComponent` | Distinguishes player from non-player entities |
| `EnemyAISystem` | `HealthSystem` declares it as a dependency to run after it |

---