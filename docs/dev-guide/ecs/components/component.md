---
title: "Components"
description: "What components exist, how they work, and how to use them."
sidebar_label: "Components"
sidebar_position: 2
---

# Components

A component is a **plain data container**: a Swift `struct` that holds state but no logic. Every component conforms to the `Component` marker protocol:

```swift
public protocol Component {}
```

Components are attached to entities and stored centrally in `ComponentStorage`. Systems query for entities that have specific components and process them each frame. Keep components as **pure data**, with no methods that mutate state, no references to other objects. Logic belongs in systems.

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

### Read a component

```swift
if let transform = world.getComponent(type: TransformComponent.self, for: entity) {
    print(transform.position)
}
```

### Mutate a component

Components are value types (`struct`). Use `modifyComponentIfExist` to mutate in place — this avoids the copy-then-reassign pattern, and silently no-ops if the component isn't present:

```swift
world.modifyComponentIfExist(type: TransformComponent.self, for: entity) { transform in
    transform.position += SIMD2<Float>(10, 0)
}
```

If you need to mutate when it exists, or add a fallback component when it doesn't, use `modifyComponent`:

```swift
world.modifyComponent(type: TransformComponent.self, for: entity, component: TransformComponent(position: .zero)) { transform in
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

