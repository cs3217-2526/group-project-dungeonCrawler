---
title: "Enemy AI System"
description: "How the EnemyAISystem works."
sidebar_position: 2
---

# Enemy AI System

`EnemyAISystem` drives enemy behaviour each frame. It runs at `priority: 15` and is responsible for transitioning each enemy between its two modes — **wander** and **chase** — and setting the enemy's velocity accordingly.

### Components Required:

For an enemy to be processed by this system, it **must have**:
- `EnemyStateComponent` — holds the current mode, speed, and radius configuration
- `TransformComponent` — provides the enemy's current position
- `VelocityComponent` — written to each frame with the computed movement vector

**Note:**
Enemies that currently have a `KnockbackComponent` are skipped entirely — knockback takes priority over AI-driven movement.

---

## Enemy Modes

| Mode | Behaviour |
|---|---|
| `wander` | Enemy moves toward a randomly chosen point within `wanderRadius`. When it arrives (within 8 units), a new target is picked. |
| `chase` | Enemy moves directly toward the player at `chaseSpeed`. |

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
    public var mode: EnemyMode          // .wander or .chase
    public var detectionRadius: Float   // Enter chase below this distance
    public var loseRadius: Float        // Return to wander above this distance
    public var wanderTarget: SIMD2<Float>? // Current wander destination (if nil, pick one next frame)
    public var wanderRadius: Float      // Max distance for a new wander target
    public var wanderSpeed: Float       // Speed while wandering
    public var chaseSpeed: Float        // Speed while chasing
}
```

**Default Values**:

| Field | Default |
|---|---|
| `detectionRadius` | `150` |
| `loseRadius` | `225` |
| `wanderRadius` | `100` |
| `wanderSpeed` | `40` |
| `chaseSpeed` | `70` |

---

## Update Loop

Each frame, `EnemyAISystem.update()` does the following for every qualifying enemy in sequence:

1. **Skip** if `KnockbackComponent` is present.
2. **Transition Enemy Mode** based on distance to player (see rules above).
3. **Compute velocity** based on the current mode:
   - **Chase** — normalise the vector toward the player, scale by `chaseSpeed`, write to `VelocityComponent`.
   - **Wander**:
     - If no `wanderTarget` exists or the enemy has arrived (within 8 units), pick a new random point within `wanderRadius`, set it as the new `wanderTarget`. Normalise the vector towards the new `wanderTarget`, scale by `wanderSpeed`, write to `VelocityComponent`.
     - If `wanderTarget` exists and the enemy has not arrived (within 8 units), normalise the vector toward the current `wanderTarget`, scale by `wanderSpeed`, write to `VelocityComponent`.

The system does not move entities directly — it only writes to `VelocityComponent`. Movement is applied by the movement system on the same frame.

---

## Adding a New Enemy Type

To customise AI behaviour for a new enemy, construct `EnemyStateComponent` with different parameters:

```swift
// Aggressive enemy — large detection range, fast chase
EnemyStateComponent(
    detectionRadius: 250,
    loseRadius: 350,
    wanderRadius: 80,
    wanderSpeed: 30,
    chaseSpeed: 120
)

// Passive enemy — short detection, slow movement
EnemyStateComponent(
    detectionRadius: 60,
    loseRadius: 100,
    wanderRadius: 150,
    wanderSpeed: 20,
    chaseSpeed: 45
)
```

No changes to `EnemyAISystem` itself are needed.

---

## Dependencies

| Dependency | Role |
|---|---|
| `EnemyStateComponent` | Holds AI mode, radii, speed, and wander target |
| `TransformComponent` | Read for enemy and player positions |
| `VelocityComponent` | Written with the computed movement vector |
| `KnockbackComponent` | Presence causes the enemy to be skipped this frame |
| `PlayerTagComponent` | Used to locate the player entity |
