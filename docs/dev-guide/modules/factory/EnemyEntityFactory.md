---
title: "EnemyEntityFactory"
description: "Creates an enemy entity for a given EnemyType."
sidebar_position: 3
---

# EnemyEntityFactory

`EnemyEntityFactory` creates an enemy entity. The `EnemyType` passed at init determines the sprite, scale, and mass of the resulting entity.

## Usage

```swift
EnemyEntityFactory(at: position, type: .mummy, baseScale: scale).make(in: world)

// baseScale defaults to 1 if omitted
EnemyEntityFactory(at: position, type: .tower).make(in: world)
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `position` | `SIMD2<Float>` | — | Spawn position in world space |
| `type` | `EnemyType` | — | Determines texture, scale multiplier, and mass |
| `baseScale` | `Float` | `1` | Base scale — multiplied by `type.scale` to get the final world scale |

## EnemyType

`EnemyType` is defined in `EnemyEntityFactory.swift`. Each case provides a texture name, a scale multiplier, and a mass value used by `KnockbackSystem`.

| Type | Texture | Scale | Mass |
|---|---|---|---|
| `.charger` | "Charger" | 1.0 | 15 |
| `.mummy` | "Mummy" | 1.0 | 10 |
| `.ranger` | "Ranger" | 0.75 | 5 |
| `.tower` | "Tower" | 1.5 | 20 |

The final in-world scale is `baseScale × type.scale`.

## Components Added

| Component | Initial Value |
|---|---|
| `TransformComponent` | `position`, rotation `0`, `baseScale × type.scale` |
| `SpriteComponent` | `type.textureName`, layer `.entity` |
| `EnemyTagComponent` | `type.textureName`, final scale |
| `VelocityComponent` | Zero |
| `EnemyStateComponent` | Default AI config |
| `CollisionBoxComponent` | `playerSize × finalScale` |
| `MassComponent` | `type.mass` |

## Adding a New Enemy Type

See [Enemies — Adding a New Enemy Type](../enemy/enemies.md#adding-a-new-enemy-type).
