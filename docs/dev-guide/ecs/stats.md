---
title: "Stats System"
sidebar_position: 4
---

# Stats System

The stats system allows entities to carry named numerical stats, such as health, move speed, attack power, without hard-coding those concepts into the engine.

## Key Types

### `StatType`

A lightweight, string-backed key that identifies a stat.

```swift
public struct StatType: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}
```

Four stat types are built in:

| Constant | Raw value | Meaning |
|---|---|---|
| `.health` | `"health"` | Hit points |
| `.moveSpeed` | `"moveSpeed"` | Units per second |
| `.attack` | `"attack"` | Outgoing damage |
| `.defence` | `"defence"` | Incoming damage reduction |

You can add your own without touching any existing file:

```swift
extension StatType {
    static let sanity = StatType(rawValue: "sanity")
}
```

---

### `StatValue`

Holds the numbers for one stat slot.

```swift
public struct StatValue {
    public var base:    Float   // unmodified starting value
    public var current: Float   // runtime value (takes damage, buffs, etc.)
    public var min:     Float   // floor (default 0)
    public var max:     Float?  // ceiling — nil means uncapped
}
```

`current` starts equal to `base`. Systems modify `current`; `base` stays as the reference point for resets or percentage calculations.

---

### `StatsComponent`

A component that stores an entity's stats as a dictionary.

```swift
public final class StatsComponent: Component {
    public var stats: [StatType: StatValue]
}
```

Read a stat with the convenience accessor:

```swift
let hp = statsComponent.value(for: .health)   // StatValue? Optional type
```

---

## How the Player is Configured

`EntityFactory.makePlayer` attaches a `StatsComponent` with these defaults:

| Stat | Base | Min | Max |
|---|---|---|---|
| `.health` | 100 | 0 | 100 |
| `.moveSpeed` | 90 | 0 | uncapped |
| `.attack` | 10 | 0 | uncapped |
| `.defence` | 0 | 0 | uncapped |

---

## Systems That Use Stats

### `HealthSystem` (priority 15)

Runs every frame. Destroys any entity whose `health.current` has reached zero or below. E.g.

```
InputSystem (10) → HealthSystem (15) → MovementSystem (20) → RenderSystem (100)
```

It does not apply damage itself — that is another system's job.

### `MovementSystem` (priority 20)

Reads `moveSpeed.current` from `StatsComponent` when present. If an entity has no `StatsComponent`, it falls back to `MovementSystem.fallbackMoveSpeed` (90), so the system is safe for non-player entities.

---

## Adding a New Stat

1. Declare the key (new file or any file — no existing file needs editing):
   ```swift
   extension StatType {
       static let sanity = StatType(rawValue: "sanity")
   }
   ```

2. Write a system that reads or writes `stats[.sanity]`:
   ```swift
   public final class SanitySystem: System {
       public let priority: Int = 16

       public func update(deltaTime: Double, world: World) {
           for entity in world.entities(with: StatsComponent.self) {
               guard let stats = world.getComponent(type: StatsComponent.self, for: entity)
               else { continue }
               // read stats.value(for: .sanity), modify stats.stats[.sanity]?.current, etc.
           }
       }
   }
   ```

3. Register the system in `GameScene.setupSystems()`:
   ```swift
   systemManager.register(SanitySystem())
   ```

Only step 3 touches an existing file, and it is a single-line addition to the bootstrap section.
