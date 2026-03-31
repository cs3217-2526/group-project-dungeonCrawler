---
title: "Stats"
description: "The shared stat foundation — StatValue, StatProvidable, and StatEventBuffer."
sidebar_position: 4
---

# Stats

The stat system provides a shared foundation used by all numeric character statistics — health, mana, move speed, and any future stats. It defines how a stat value is stored, how stat components are typed, and how stat changes can be communicated across systems.

---

## StatValue

`StatValue` is the core value type stored inside every stat component. It tracks three numbers for a single stat:

| Field | Type | Description |
|---|---|---|
| `base` | `Float` | The baseline value, set at initialisation. Used as the starting `current`. |
| `current` | `Float` | The live value modified at runtime (e.g. damage taken, mana spent). |
| `max` | `Float?` | Optional ceiling for `current`. If `nil`, no upper bound is enforced. |

```swift
public struct StatValue {
    public var base: Float
    public var current: Float
    public var max: Float?

    public init(base: Float, max: Float? = nil)
}
```

`current` is initialised to `base`. Provide `max` when the stat needs a ceiling (health, mana). Omit it for uncapped stats (move speed).

### Clamping

`StatValue` provides two mutating helpers for keeping `current` in range. Call these after modifying `current` directly:

```swift
// Cap current at max (no-op if max is nil)
value.clampToMax()

// Floor current at 0 (or a custom floor)
value.clampToMin()
value.clampToMin(1)  // custom floor
```

---

## StatProvidable

`StatProvidable` is a protocol that all stat components conform to. It requires a single `value: StatValue` property, which lets systems interact with any stat component generically without knowing the concrete type.

```swift
public protocol StatProvidable: Component {
    var value: StatValue { get set }
}
```

**Stat components that conform to `StatProvidable`:**

| Component | Stat |
|---|---|
| `HealthComponent` | Player and enemy hit points |
| `ManaComponent` | Player spell resource |
| `MoveSpeedComponent` | Entity movement speed |

---

## StatEventBuffer

`StatEventBuffer` is a shared bus for recording stat changes in a frame. It is not consumed by any built-in system but is available for UI, audio, or effect systems that need to react to stat changes without directly polling components.

```swift
public final class StatEventBuffer {
    public private(set) var changes: [StatChangeEvent] = []

    public func recordChange(entity: Entity, componentType: any StatProvidable.Type, amount: Float)
    public func clear()
}
```

Each `StatChangeEvent` carries:

| Field | Description |
|---|---|
| `entity` | The entity whose stat changed |
| `componentType` | The `StatProvidable`-conforming component type (e.g. `HealthComponent.self`) |
| `amount` | The delta applied (negative = loss, positive = gain) |

### Usage pattern

Any system that modifies a stat can optionally record the change:

```swift
statEventBuffer.recordChange(
    entity: player,
    componentType: HealthComponent.self,
    amount: -15
)
```

Call `clear()` at the start or end of each frame to prevent stale events from accumulating:

```swift
statEventBuffer.clear()
```

---

## Adding a New Stat

1. Create a new component conforming to `StatProvidable`:

```swift
public struct StaminaComponent: StatProvidable {
    public var value: StatValue

    public init(base: Float, max: Float) {
        self.value = StatValue(base: base, max: max)
    }
}
```

2. Attach it to entities at spawn time:

```swift
world.addComponent(component: StaminaComponent(base: 100, max: 100), to: player)
```

3. Optionally create a dedicated system (see [Health](./health.md) and [Mana](./mana.md) for examples).

No changes to `StatValue` or `StatProvidable` are needed.

---