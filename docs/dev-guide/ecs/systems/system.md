---
title: "Systems"
description: "How systems work, what systems exist, and how to write a new one."
sidebar_label: "Systems"
sidebar_position: 3
---

# Systems

A system contains the **game logic**. Each frame, `SystemManager` calls every registered system in dependency order. Systems read and write component data via `World`, and do not talk to each other directly.

---

## The `System` Protocol

```swift
public protocol System: AnyObject {

    /// Systems that must finish before this system runs each update.
    var dependencies: [System.Type] { get }

    /// Called once per game-loop tick.
    func update(deltaTime: Double, world: World)
}
```

Systems are reference types (`AnyObject`) so they can hold internal state (e.g. node registries, weak references to external objects).

The `dependencies` property has a default implementation that returns `[]`, so systems with no prerequisites don't need to override it.

---

## Declaring Dependencies

Instead of assigning a manual priority number, a system declares which other systems must run before it:

```swift
final class MovementSystem: System {
    // No dependencies — runs as early as possible
    func update(deltaTime: Double, world: World) { ... }
}

final class CollisionSystem: System {
    // Must run after positions are updated
    var dependencies: [System.Type] { [MovementSystem.self] }

    func update(deltaTime: Double, world: World) { ... }
}

final class CombatSystem: System {
    // Must run after collisions are resolved
    var dependencies: [System.Type] { [CollisionSystem.self] }

    func update(deltaTime: Double, world: World) { ... }
}
```

Only declare **direct** prerequisites. Transitive ordering is inferred automatically — you don't need to list every upstream system.

---

## SystemManager

`SystemManager` owns all active systems. On every `update` call it calls each system's `update` in the previously sorted order.

The sorted order is (re)computed lazily: `register` and `unregister` set a dirty flag, and the next `update` call rebuilds the order by:

1. Building a **directed acyclic graph (DAG)** from each system's `dependencies`.
2. Running a **topological sort** (Kahn's algorithm) to produce a valid execution order.

Frames where no system is added or removed pay no sorting cost.

```swift
let systemManager = SystemManager()

// Register systems — order of registration doesn't matter
systemManager.register(CombatSystem())
systemManager.register(MovementSystem())
systemManager.register(CollisionSystem())

// Unregister by type
systemManager.unregister(CombatSystem.self)

// Drive everything — called once per frame
systemManager.update(deltaTime: deltaTime, world: world)
```

### Cycle Detection

If a circular dependency is introduced (e.g. `A → B → A`), `SystemManager` fires an `assert` at the point the cycle is detected. Asserts are stripped in release builds — cycles are considered a programmer error caught during development.

---

## Writing a New System

1. Create a `final class` conforming to `System`.
2. Override `dependencies` if this system must run after others.
3. Implement `update(deltaTime:world:)`.
4. Register it with `SystemManager`.

```swift
final class MySystem: System {
    var dependencies: [System.Type] { [MovementSystem.self] }

    func update(deltaTime: Double, world: World) {
        let entities = world.getEntities(with: [MyComponent.self])
        for entity in entities {
            guard var comp = world.getComponent(type: MyComponent.self, for: entity) else { continue }
            // mutate comp...
            world.addComponent(component: comp, to: entity)
        }
    }
}
```

> **Tip:** Only declare direct prerequisites. If `MySystem` depends on `CollisionSystem`, and `CollisionSystem` already depends on `MovementSystem`, you don't need to list `MovementSystem` in `MySystem.dependencies`.

---

## System Reference

All currently registered systems, their responsibilities, and their direct dependencies.

| System | Responsibility | Dependencies |
|---|---|---|
| `InputSystem` | Drains `CommandQueues` and writes intent (move direction, facing, etc.) into `InputComponent` | _(none)_ |
| `LevelTransitionSystem` | Detects when the player crosses a room boundary and triggers a transition via `LevelOrchestrator` | _(none)_ |
| `KnockbackSystem` | Applies active `KnockbackComponent` velocity to `TransformComponent` each tick | `LevelTransitionSystem` |
| `EnemyAISystem` | Runs each enemy's AI strategy to compute its desired velocity / facing | `KnockbackSystem` |
| `HealthSystem` | Processes pending damage / healing on `HealthComponent`; handles death | `EnemyAISystem` |
| `MovementSystem` | Integrates velocity from `VelocityComponent` into `TransformComponent` for all entities | `InputSystem`, `EnemyAISystem`, `KnockbackSystem` |
| `CollisionSystem` | Detects and resolves collisions; writes to `CollisionEventBuffer` and `DestructionQueue` | `MovementSystem`, `HealthSystem` |
| `WeaponSystem` | Ticks weapon cooldowns and spawns projectile entities on fire | `CollisionSystem` |
| `ProjectileSystem` | Moves active projectiles; reads `CollisionEventBuffer` to apply hit effects and queue destruction | `WeaponSystem` |
| `CameraSystem` | Lerps the `ViewportComponent` toward the entity tagged with `CameraFocusComponent` | `MovementSystem` |
| `HUDSystem` | Pushes player health / mana values to the HUD backend; processes joystick render commands | `HealthSystem` |
| `RenderSystem` | Draws all visible entities via `RenderingBackend` | `CameraSystem`, `HUDSystem`, `ProjectileSystem` |


### Dependency Graph

```
InputSystem          LevelTransitionSystem
     │                       │
     │               KnockbackSystem
     │                  │       │
     │             EnemyAISystem │
     │              │    │       │
     └──────────────┘    │       │
                         │       │
              HealthSystem    MovementSystem
                    │           │        │
                    └─────┬─────┘        │
                          │              │
                    CollisionSystem   CameraSystem
                          │
                     WeaponSystem
                          │
                   ProjectileSystem    HUDSystem
                          └──────┬──────┘
                                 │
                           RenderSystem
```
