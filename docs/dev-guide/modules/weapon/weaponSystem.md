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

### Cooldown

The cooldown is tracked using an internal `gameTime: Float` accumulator (sum of all `deltaTime` values) compared against `WeaponComponent.lastFiredAt`.

```swift
let isReadyToFire = (gameTime - weaponComponent.lastFiredAt) >= Float(weaponComponent.coolDownInterval)
```

The default handgun `coolDownInterval` is **0.2 s**.

### Fire Direction Fallback

If the aim vector has near-zero length (the player isn't actively aiming), the system falls back to the owner's facing direction:

```swift
if simd_length_squared(fireDirection) < 0.001 * 0.001 {
    fireDirection = facingRight ? SIMD2<Float>(1, 0) : SIMD2<Float>(-1, 0)
}
```

This prevents projectiles being spawned with a zero-length velocity vector.

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
