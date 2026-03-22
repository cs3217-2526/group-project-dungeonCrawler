---
title: "Weapon Component"
description: "How weapon entities are created and managed."
sidebar_position: 1
---

# Weapon Component

`WeaponComponent` stores the firing stats for a weapon entity. Each weapon is its own ECS entity, linked to an owner (e.g. the player) via `OwnerComponent`.

## WeaponComponent

```swift
struct WeaponComponent: Component {
    var type: WeaponType
    var manaCost: Float
    var attackSpeed: Float
    var coolDownInterval: TimeInterval
    var lastFiredAt: Float
}
```

| Property | Type | Description |
|---|---|---|
| `type` | `WeaponType` | Which kind of weapon this is (`.handgun`, `.sword`, `.bow`) |
| `manaCost` | `Float` | Mana consumed per shot |
| `attackSpeed` | `Float` | Attack speed multiplier (reserved for future use) |
| `coolDownInterval` | `TimeInterval` | Minimum seconds between shots |
| `lastFiredAt` | `Float` | Game-time timestamp of the last fired shot, used to gate cooldown |

### WeaponType

```swift
enum WeaponType: String {
    case handgun
    case sword
    case bow
}
```

Currently only `handgun` is fully implemented. `sword` and `bow` are reserved for future weapon types.

## EquippedWeaponComponent

```swift
struct EquippedWeaponComponent: Component {
    var primaryWeapon: Entity
    var secondaryWeapon: Entity?
}
```

Attached to the **owner** entity (e.g. the player) to reference its weapon entities. A player must have a primary weapon and may optionally have a secondary weapon.

> Weapon switching, dropping, and picking up are planned but not yet implemented.

## Creating a Weapon Entity

Weapons are created via `EntityFactory.makeWeapon`:

```swift
let weapon = EntityFactory.makeWeapon(
    in: world,
    ownedBy: playerEntity,
    textureName: "handgun",
    offset: SIMD2<Float>(20, -5),
    scale: 1.0
)
```

This attaches to the new entity:
- `TransformComponent` — positioned at the owner's location plus the given offset
- `FacingComponent` — inherits the owner's facing direction
- `SpriteComponent` — renders the weapon sprite
- `OwnerComponent` — links back to the owner and stores the offset
- `WeaponComponent` — sets type `.handgun`, `manaCost: 10`, `coolDownInterval: 0.2`

## Dependencies

| Dependency | Role |
|---|---|
| `OwnerComponent` | Links the weapon entity to its owner and stores the positional offset |
| `FacingComponent` | Determines which direction the weapon sprite is flipped |
| `WeaponSystem` | Updates weapon position/rotation each frame and fires projectiles |
| `EntityFactory` | Factory method for creating weapon entities |
