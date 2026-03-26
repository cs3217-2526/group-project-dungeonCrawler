---
title: "ProjectileEntityFactory"
description: "Creates a single projectile (bullet) entity."
sidebar_position: 5
---

# ProjectileEntityFactory

`ProjectileEntityFactory` creates a single projectile entity. It is called by `WeaponSystem` each time the player fires.

## Usage

```swift
ProjectileEntityFactory(
    from: position,
    aimAt: direction,
    speed: 400,
    effectiveRange: 300,
    owner: playerEntity
).make(in: world)
```

## Parameters

| Parameter | Type | Description |
|---|---|---|
| `position` | `SIMD2<Float>` | Spawn position (typically the weapon's current position) |
| `direction` | `SIMD2<Float>` | Normalised aim vector |
| `speed` | `Float` | Initial speed (applied as `direction × speed` to `VelocityComponent`) |
| `effectiveRange` | `Float` | Max distance the projectile travels before being destroyed |
| `owner` | `Entity` | The entity that fired the projectile (used to avoid self-collision) |

## Components Added

| Component | Initial Value |
|---|---|
| `TransformComponent` | `position`, rotation derived from `direction`, scale `1` |
| `VelocityComponent` | `direction × speed` |
| `SpriteComponent` | `"normalHandgunBullet"`, layer `.projectile` |
| `ProjectileComponent` | Damage `10`, `owner` |
| `EffectiveRangeComponent` | `base: effectiveRange` |
| `CollisionBoxComponent` | `6 × 6` |

## Rotation

The bullet's rotation is computed from the aim direction so the sprite points in the direction of travel:

- Travelling right (`direction.x >= 0`): `atan2(direction.y, direction.x)`
- Travelling left: `-atan2(direction.y, -direction.x)`
