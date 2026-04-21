---
title: "Components"
description: "What components exist, how they work, and how to use them."
sidebar_label: "Components"
sidebar_position: 2
---

# Components

A component is a **plain data container**: a Swift `class` that holds state but no logic. Every component conforms to the `Component` marker protocol:

```swift
public protocol Component {}
```

Components are attached to entities and stored centrally in `ComponentStorage`. Systems query for entities that have specific components and process them each frame. Because components are now **reference types (classes)**, you can mutate their data directly without needing to re-assign them to the world.

Keep components as **pure data**, with no methods that encapsulate logic—logic belongs in systems.

---

## Component Storage

Under the hood, components are stored in two layers:

- **`ComponentStore<T>`** — a per-type dictionary `[EntityID: T]` that holds all components of a single type.
- **`ComponentStorage`** — a type-erased registry that maps `ObjectIdentifier(T.self)` to its `ComponentStore<T>`.

These are generally never interacted with directly. Use the `World` API instead.

---

## Working with Components via World

### Add a component

```swift
world.addComponent(component: TransformComponent(position: .zero), to: entity)
```

### Read and Mutate a component

Since components are classes, you can retrieve a reference and modify its properties directly. These changes are immediately reflected in the ECS world.

```swift
if let transform = world.getComponent(type: TransformComponent.self, for: entity) {
    // Reading
    print(transform.position)

    // Mutating directly on the reference
    transform.position += SIMD2<Float>(10, 0)
}
```

### Remove a component

```swift
world.removeComponent(type: VelocityComponent.self, from: entity)
```

### Query all entities with a component

```swift
let movingEntities = world.entities(with: VelocityComponent.self)
```

### Query entities with two components (binary join)

Returns a tuple array `[(entity, a, b)]` — only entities with **both** components are included:

```swift
let renderables = world.entities(with: TransformComponent.self, and: SpriteComponent.self)
for (entity, transform, sprite) in renderables {
    // ...
}
```

## Weapons

- `WeaponComponent` — the weapon type, mana cost, attack speed, cooldown interval, and tracks when it was last fired.
- `OwnerComponent` — links the weapon to the entity (for example, the player) that currently owns or has equipped it.
- `TransformComponent` — determines where the weapon is in the world (position and rotation) so it can spawn projectiles correctly.
- `SpriteComponent` — provides rendering data so the weapon can be drawn by the rendering system.

## Projectiles

Projectiles are entities that are spawned by the weapon if the weapon is fired.

Note that projectiles are NOT a special weapon but are entities that are spawned by the weapon if the weapon is fired.

