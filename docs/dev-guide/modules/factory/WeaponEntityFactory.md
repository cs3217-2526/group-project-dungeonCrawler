---
title: "WeaponEntityFactory"
description: "Creates a weapon entity attached to a player entity."
sidebar_position: 4
---

# WeaponEntityFactory

`WeaponEntityFactory` creates a weapon entity and links it to an existing player entity via `OwnerComponent`.

## Usage

```swift
WeaponEntityFactory(ownedBy: playerEntity, scale: scale).make(in: world)

// With explicit offset and texture
WeaponEntityFactory(
    ownedBy: playerEntity,
    textureName: "handgun",
    offset: SIMD2(10, -5),
    scale: scale,
    lastFiredAt: 0
).make(in: world)
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `player` | `Entity` | — | The player entity this weapon belongs to |
| `textureName` | `String` | `"handgun"` | Asset catalog name for the weapon sprite |
| `offset` | `SIMD2<Float>` | `.zero` | Position offset relative to the player |
| `scale` | `Float` | `1` | World scale |
| `lastFiredAt` | `Float` | `0` | Timestamp of the last shot (used to restore cooldown state) |

## Components Added

| Component | Initial Value |
|---|---|
| `TransformComponent` | Player position + `offset`, rotation `0`, `scale` |
| `FacingComponent` | Copied from the player's current facing |
| `SpriteComponent` | `textureName`, layer `.weapon` |
| `OwnerComponent` | `ownerEntity: player`, `offset` |
| `WeaponComponent` | Type `.handgun`, mana cost `10`, attack speed `1`, cooldown `0.2s`, `lastFiredAt` |
