---
title: "EntityFactory"
description: "The EntityFactory protocol and how factories are structured."
sidebar_position: 1
---

# EntityFactory

`EntityFactory` is a protocol that all entity factories implement. It defines a single method for creating an entity in a given world.

```swift
public protocol EntityFactory {
    @discardableResult
    func make(in world: World) -> Entity
}
```

Each concrete factory is a struct that accepts its configuration via `init`, then creates and returns a fully wired entity when `make(in: world)` is called.

## Concrete Factory's Usage

```swift
// 1. Construct the factory with configuration
let factory = EnemyEntityFactory(at: position, type: .mummy, baseScale: scale)

// 2. Call make to spawn the entity
let entity = factory.make(in: world)
```

The return value is `@discardableResult` — you can ignore it if you don't need a reference to the created entity.

## Concrete Factories

| Factory | Creates |
|---|---|
| `PlayerEntityFactory` | The player character |
| `EnemyEntityFactory` | An enemy of a given `EnemyType` |
| `WeaponEntityFactory` | A weapon attached to a player entity |
| `ProjectileEntityFactory` | A single projectile (e.g. bullet) |
| `RoomEntityFactory` | A room with bounds, doorways, and spawn points |
