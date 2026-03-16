---
title: "Systems"
description: "How systems work, what systems exist, and how to write a new one."
sidebar_label: "Systems"
sidebar_position: 3
---

# Systems

A system contains the **game logic**. Each frame, `SystemManager` calls every registered system in priority order. Systems read and write component data via `World`, and do not talk to each other directly.

---

## The `System` Protocol

```swift
public protocol System: AnyObject {
    /// Lower values run first. Use steps of 10 to leave room for insertions.
    var priority: Int { get }

    /// Called once per game-loop tick.
    func update(deltaTime: Double, world: World)
}
```

Systems are reference types (`AnyObject`) so they can hold internal state (e.g. node registries, weak references to external objects).

---

## SystemManager

`SystemManager` owns the list of active systems and keeps them sorted by `priority`.

```swift
let systemManager = SystemManager()

// Register a system
systemManager.register(MovementSystem())

// Unregister by type
systemManager.unregister(MovementSystem.self)

// Drive everything — called once per frame
systemManager.update(deltaTime: deltaTime, world: world)
```

Systems are executed in ascending priority order on every `update` call.

---

### Systems

In the future?