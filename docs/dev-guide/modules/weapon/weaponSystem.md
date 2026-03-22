---
title: "Weapon System"
description: "How the weapon system positions weapons and fires projectiles."
sidebar_position: 2
---

# Weapon System

`WeaponSystem` is the ECS system responsible for keeping weapon entities attached to their owner, rotating them to match the aim direction, and spawning projectiles when the owner fires. It runs at `priority: 50`.

## Responsibilities

| Responsibility | Description |
|---|---|
| Position weapon | Moves the weapon entity to the owner's position plus the configured offset each frame |
| Rotate weapon | Rotates the weapon to face the current `InputComponent.aimDirection`, mirroring the angle when facing left |
| Sync facing | Updates `FacingComponent` on the weapon to match the owner so the sprite flip is correct |
| Fire projectile | Spawns a projectile entity via `EntityFactory.makeProjectile` when the owner is shooting and the cooldown has elapsed |

## Update Loop

`WeaponSystem.update` iterates over all entities that have **all four** of:
- `WeaponComponent`
- `OwnerComponent`
- `FacingComponent`
- `TransformComponent`

For each such weapon entity it:

1. **Resolves the owner** — reads `TransformComponent` and `InputComponent` from the owner entity. Skips the weapon if either is missing.
2. **Mirrors the offset** — flips the x-component of `OwnerComponent.offset` when the owner is facing left.
3. **Computes rotation** — `atan2(aimDir.y, aimDir.x)` when facing right; `-atan2(aimDir.y, -aimDir.x)` when facing left.
4. **Writes position & rotation** back to the weapon's `TransformComponent`.
5. **Syncs facing** — sets the weapon's `FacingComponent` to match the owner's.
6. **Checks fire input** — if `ownerInput.isShooting` and the cooldown has elapsed (`gameTime - lastFiredAt >= coolDownInterval`), calls `EntityFactory.makeProjectile` and records `lastFiredAt = gameTime`.

### Facing & Aiming Priority

Facing and aim direction feed into two separate decisions each frame. Both follow an explicit priority/fallback order.

#### 1. Determining `facingRight` (the weapon should be on left or right side of the owner)

| Priority | Source | Condition |
|---|---|---|
| 1 | `ownerFacing.facing` from owner's `FacingComponent` | Owner has a `FacingComponent` |
| 2 | Default — **facing right** | Owner has no `FacingComponent` (`ownerFacing` is `nil`) |

`facingRight` is `true` unless the owner's facing is explicitly `.left`:

```swift
let facingRight = ownerFacing?.facing != .left
```

> This `facingRight` value is used for both mirroring the weapon's position offset and determining the rotation formula to apply to the aim vector. See [Weapon Rotation](#2-weapon-rotation-which-direction-to-aim) and [Fire Direction](#3-fire-direction-which-direction-to-shoot) below.

#### 2. Weapon rotation (which direction to aim)

`facingRight` is a subdivision criterion: it selects which rotation formula to apply to the aim vector.

| Priority | Value | Condition |
|---|---|---|
| 1 | `atan2(aimDir.y, aimDir.x)` (facing right) or `-atan2(aimDir.y, -aimDir.x)` (facing left) | `simd_length(aimDir) > 0.001` |
| 2 | `0` (no rotation) | Aim vector is near-zero |

The left-facing formula negates both the result and the x-component of the input so that the angle is mirrored correctly against the flipped sprite xScale.

#### 3. Fire direction (which direction to shoot)

| Priority | Value | Condition |
|---|---|---|
| 1 | `ownerInput.aimDirection` | `simd_length_squared(aimDir) >= 0.001²` |
| 2 | `(1, 0)` or `(-1, 0)` based on `facingRight` | Aim vector is near-zero |

This fallback ensures a projectile is never spawned with a zero-length velocity vector (see [Fire Direction Fallback](#fire-direction-fallback) below).

##### Fire Direction Fallback

If the aim vector has near-zero length (the player isn't actively aiming), the system falls back to the owner's facing direction:

```swift
if simd_length_squared(fireDirection) < 0.001 * 0.001 {
    fireDirection = facingRight ? SIMD2<Float>(1, 0) : SIMD2<Float>(-1, 0)
}
```

This prevents projectiles being spawned with a zero-length velocity vector (which would cause them to not move never get destroyed).

---

### Cooldown

The cooldown is tracked using an internal `gameTime: Float` accumulator (sum of all `deltaTime` values) compared against `WeaponComponent.lastFiredAt`.

```swift
let isReadyToFire = (gameTime - weaponComponent.lastFiredAt) >= Float(weaponComponent.coolDownInterval)
```

The default handgun `coolDownInterval` is **0.2 s**.

## Usage Example

```swift
// Weapon entity is created once via EntityFactory.makeWeapon.
// WeaponSystem handles positioning and firing automatically every frame.
let weapon = EntityFactory.makeWeapon(in: world, ownedBy: playerEntity, offset: SIMD2<Float>(20, -5))
```

## Dependencies

| Dependency | Role |
|---|---|
| `WeaponComponent` | Stores fire stats (cooldown, mana cost, `lastFiredAt`) |
| `OwnerComponent` | Provides the owner entity reference and positional offset |
| `FacingComponent` | Determines left/right mirroring for position and rotation |
| `InputComponent` | Supplies `aimDirection` and `isShooting` from the owner |
| `TransformComponent` | Read from the owner; written to the weapon entity |
| `EntityFactory.makeProjectile` | Creates projectile entities when the weapon fires |
