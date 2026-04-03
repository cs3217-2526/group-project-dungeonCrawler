---
title: "Enemy AI System"
description: "How the EnemyAISystem works."
sidebar_position: 2
---

# Enemy AI System

`EnemyAISystem` drives enemy behaviour each frame. It runs after `KnockbackSystem` and is responsible for transitioning each enemy between its two modes — **wander** and **chase** — and delegating movement to the appropriate strategy.

### Components Required

For an enemy to be processed by this system, it **must have**:
- `EnemyStateComponent` — holds the current mode, detection radii, and the two strategy instances
- `TransformComponent` — provides the enemy's current position
- `VelocityComponent` — written to each frame by the active strategy

**Note:**
Enemies that currently have a `KnockbackComponent` are skipped entirely — knockback takes priority over AI-driven movement.

---

## Enemy Modes

| Mode | Behaviour |
|---|---|
| `wander` | Delegates to `EnemyStateComponent.wanderStrategy` |
| `chase` | Delegates to `EnemyStateComponent.chaseStrategy` |

---

## Mode Transitions

Every frame, the system measures the distance from the enemy to the player and applies these rules:

- If distance ≤ `detectionRadius` → switch to **chase**
- If distance > `loseRadius` → switch to **wander**
- If distance is between `detectionRadius` and `loseRadius` → mode is **unchanged** (hysteresis)

This hysteresis band prevents rapid toggling when the player sits near the detection boundary.

---

## EnemyStateComponent

`EnemyStateComponent` holds all per-enemy AI configuration and runtime state.

```swift
public struct EnemyStateComponent: Component {
    public var mode: EnemyMode                  // .wander or .chase
    public var detectionRadius: Float           // Enter chase below this distance
    public var loseRadius: Float                // Return to wander above this distance
    public var wanderStrategy: any EnemyAIStrategy
    public var chaseStrategy: any EnemyAIStrategy
}
```

**Default Values**:

| Field | Default |
|---|---|
| `detectionRadius` | `150` |
| `loseRadius` | `225` |
| `wanderStrategy` | `WanderStrategy()` |
| `chaseStrategy` | `StraightLineChaseStrategy()` |

---

## Strategy Protocol

All strategies conform to `EnemyAIStrategy`:

```swift
public protocol EnemyAIStrategy {
    func update(entity: Entity,
                transform: TransformComponent,
                playerPos: SIMD2<Float>,
                world: World)
}
```

Each strategy is responsible for writing to `VelocityComponent` (or any other component it manages) directly via the `world`.

---

## Built-in Strategies

### `WanderStrategy`

Moves the enemy to random points within a radius around its current position. Wander target state is stored in `WanderTargetComponent`, which is lazily added to the entity on first use.

| Parameter | Default | Description |
|---|---|---|
| `wanderRadius` | `100` | Max distance from current position for a new wander target |
| `wanderSpeed` | `40` | Movement speed while wandering |

```swift
WanderStrategy(wanderRadius: 100, wanderSpeed: 40)
```

**Associated component:** `WanderTargetComponent` — stores the current wander destination as `SIMD2<Float>?`. Added lazily; enemies that never wander will never have it.

---

### `StraightLineChaseStrategy`

Moves the enemy directly toward the player at a fixed speed.

| Parameter | Default | Description |
|---|---|---|
| `chaseSpeed` | `70` | Movement speed while chasing |

```swift
StraightLineChaseStrategy(chaseSpeed: 70)
```

---

### `StationaryStrategy`

Does nothing — the enemy does not move. Useful as a wander or chase strategy for tower-type enemies that only attack from a fixed position.

```swift
StationaryStrategy()
```

---

### `ShooterBasicStrategy`

A chase strategy for shooter-type enemies. The enemy orbits the player by hopping between target spots within an annular zone (ring) around the player. Each hop is constrained to within `±arcRange` of the enemy's current angle, forming a zigzag arc. The enemy briefly stops between hops.

Target positions are stored in polar coordinates relative to the player so they track the player as they move.

| Parameter | Default | Description |
|---|---|---|
| `innerRadius` | `100` | Closest distance the enemy will get to the player |
| `outerRadius` | `200` | Furthest distance the enemy will stand from the player |
| `moveSpeed` | `60` | Movement speed between hop targets |
| `arcRange` | `π/3` | Max angular deviation per hop (radians) |

```swift
ShooterBasicStrategy(innerRadius: 100, outerRadius: 200, moveSpeed: 60, arcRange: .pi / 3)
```

**Associated component:** `ShooterBasicComponent` — stores the current hop target as polar coordinates (`targetAngle`, `targetRadius`) relative to the player. Added lazily on first use.

---

## Update Loop

Each frame, `EnemyAISystem.update()` does the following for every qualifying enemy:

1. **Skip** if `KnockbackComponent` is present.
2. **Transition mode** based on distance to player (see rules above).
3. **Delegate** to `chaseStrategy.update(...)` or `wanderStrategy.update(...)` based on current mode.

The system itself does not write velocity — that is each strategy's responsibility.

---

## Adding a New Strategy

1. Define a `struct` conforming to `EnemyAIStrategy`.
2. Implement `update(entity:transform:playerPos:world:)` — write to `VelocityComponent` (and any other components your strategy manages) via `world`.
3. If your strategy needs per-entity state, create a companion `Component` struct and add it lazily in `update`.

```swift
public struct MyCustomStrategy: EnemyAIStrategy {
    public var speed: Float

    public func update(entity: Entity, transform: TransformComponent,
                       playerPos: SIMD2<Float>, world: World) {
        // compute and write velocity
        world.modifyComponentIfExist(type: VelocityComponent.self, for: entity) { vel in
            vel.linear = /* ... */ .zero
        }
    }
}
```

Then assign it when constructing `EnemyStateComponent`:

```swift
EnemyStateComponent(
    chaseStrategy: MyCustomStrategy(speed: 80)
)
```

No changes to `EnemyAISystem` itself are needed.

---

## Dependencies

| Dependency | Role |
|---|---|
| `EnemyStateComponent` | Holds AI mode, radii, and strategy instances |
| `TransformComponent` | Read for enemy and player positions |
| `VelocityComponent` | Written by the active strategy each frame |
| `KnockbackComponent` | Presence causes the enemy to be skipped this frame |
| `PlayerTagComponent` | Used to locate the player entity |
| `WanderTargetComponent` | Per-entity wander state, managed by `WanderStrategy` |
| `ShooterBasicComponent` | Per-entity hop state, managed by `ShooterBasicStrategy` |
