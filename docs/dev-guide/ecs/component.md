---
title: "Components"
description: "What components exist, how they work, and how to use them."
sidebar_label: "Components"
sidebar_position: 2
---

# Components

A component is a **plain data container**,  a Swift `struct` that holds state but no logic. Every component conforms to the `Component` marker protocol:

```swift
public protocol Component {}
```

Components are attached to entities and stored centrally in `ComponentStorage`. Systems query for entities that have specific components and process them each frame. Keep components as **pure data**, with no methods that mutate state, no references to other objects. Logic belongs in systems.

---

## Component Storage

Under the hood, components are stored in two layers:

- **`ComponentStore<T>`** — a per-type dictionary `[Entity: T]` that holds all components of a single type.
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

Components are value types (`struct`). Use `modifyComponent` to mutate in place — this avoids the copy-then-reassign pattern:

```swift
world.modifyComponent(type: TransformComponent.self, for: entity) { transform in
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

## Components

In the future?

