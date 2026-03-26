---
title: "PlayerEntityFactory"
description: "Creates the player entity with all required components."
sidebar_position: 2
---

# PlayerEntityFactory

`PlayerEntityFactory` creates the player character entity.

## Usage

```swift
// Default texture is "knight"
PlayerEntityFactory(at: position, scale: scale).make(in: world)

// Customise the texture using parameter: textureName
PlayerEntityFactory(at: position, textureName: "knight", scale: scale).make(in: world)
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `position` | `SIMD2<Float>` | — | Spawn position in world space |
| `textureName` | `String` | `"knight"` | Asset catalog name for the player sprite |
| `scale` | `Float` | `1` | World scale (derived from screen size at spawn time) |

## Components Added

| Component | Initial Value |
|---|---|
| `TransformComponent` | `position`, rotation `0`, `scale` |
| `VelocityComponent` | Zero |
| `InputComponent` | Empty |
| `SpriteComponent` | `textureName`, layer `.entity` |
| `PlayerTagComponent` | — |
| `CameraFocusComponent` | — |
| `HealthComponent` | `base: 100` |
| `MoveSpeedComponent` | `base: 90` |
| `CollisionBoxComponent` | `playerSize × scale` |
| `FacingComponent` | Default (`.right`) |
| `MassComponent` | Default (`10`) |
