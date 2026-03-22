---
title: "Map System"
description: "How rooms are generated and activated."
---

# Map System

`MapSystem` is the ECS system responsible for creating rooms, populating them with geometry and enemies, and placing the player at the correct entry point. It runs early in the update cycle (`priority: 5`) so all room state is ready before movement, collision, and rendering systems run.

## Responsibilities

| Responsibility | Method |
|---|---|
| Create a room entity and generate its interior | `generateAndActivateRoom(bounds:world:doorways:size:)` |
| Place the player at the room's entry spawn point | `spawnPlayerInRoom(room:world:size:)` |

`MapSystem.update()` is currently a no-op — the system is called imperatively from `GameScene` at startup and will be extended when room transitions are implemented.

## Generating a Room

```swift
let bounds = RoomBounds(
    origin: SIMD2<Float>(-300, -200),
    size:   SIMD2<Float>(600, 400)
)
let room = mapSystem.generateAndActivateRoom(bounds: bounds, world: world, size: view.bounds.size)
mapSystem.spawnPlayerInRoom(room: room, world: world, size: view.bounds.size)
```

`generateAndActivateRoom` performs these steps in order:

1. **Create the room entity** via `EntityFactory.makeRoom` — attaches `RoomComponent` and `TransformComponent`.
2. **Generate the interior** via `RoomGenerator.generateRoomInterior` — creates perimeter wall entities and a floor entity.
3. **Add spawn points** — one `playerEntry` point (at room centre, or offset from the first doorway if one exists) and three random `enemy` spawn points within the room bounds.
4. **Spawn enemies** at the enemy spawn points that fall within the room bounds.
5. **Tag the room** with `RoomLockedTag` and `RoomInCombatTag`.

## Spawn Points

Spawn points are stored on `RoomComponent.spawnPoints` as `[SpawnPoint]` values. There are two types:

```swift
public enum SpawnType {
    case playerEntry   // Where the player appears when entering
    case enemy         // Where an enemy is spawned
}
```

**Player entry** — if the room has a `Doorway`, the entry point is offset 50 units inward along the doorway's direction vector. If there are no doorways, the entry point defaults to `bounds.center`.

**Enemy spawns** — for now five positions are sampled via `RoomBounds.randomPosition(margin: 80)`. Any point that falls outside the room bounds is skipped at spawn time (this can happen if the margin exceeds the room's smaller dimension). In future, we will have fixed locations for enemy spawns, and some rooms may have no enemies at all.

## Spawning the Player

```swift
mapSystem.spawnPlayerInRoom(room: room, world: world, size: screenSize)
```

This method finds the `playerEntry` spawn point on the room and either:

- **Moves** the existing player entity's `TransformComponent` to the entry position, or
- **Creates** a new player entity via `EntityFactory.makePlayer` if none exists yet.

This means it is safe to call `spawnPlayerInRoom` for subsequent rooms without duplicating the player entity.

## Room Scale

Enemy and player scale is derived from screen size to keep characters visually consistent across device sizes:

```swift
let scale = Float(min(size.width, size.height)) * 0.04 / 48.0
```

This targets a character height of ~4% of the shorter screen dimension, assuming the base sprite is 48×48 pixels.

## Adding a New Room

To generate a second room (e.g. on transition), call `generateAndActivateRoom` with new bounds and doorways, then call `spawnPlayerInRoom` with the new room entity. The player will be moved to the new room's entry point automatically.

```swift
// Future: room transition example
let nextBounds = RoomBounds(origin: ..., size: ...)
let nextDoorways = [Doorway(position: ..., direction: .north)]
let nextRoom = mapSystem.generateAndActivateRoom(
    bounds: nextBounds, world: world, doorways: nextDoorways, size: screenSize
)
mapSystem.spawnPlayerInRoom(room: nextRoom, world: world, size: screenSize)
```

## Dependencies

| Dependency | Role |
|---|---|
| `RoomGenerator` | Creates wall, floor, and obstacle entities inside the room bounds |
| `EntityFactory` | Creates the room entity, player entity, and enemy entities |
| `World` | All entities and components are stored and queried here |