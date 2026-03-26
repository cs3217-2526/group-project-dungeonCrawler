---
title: "RoomEntityFactory"
description: "Creates a room entity with bounds, doorways, and spawn points."
sidebar_position: 6
---

# RoomEntityFactory

`RoomEntityFactory` creates a room entity. In normal gameplay, this is called by `MapSystem` — you rarely need to call it directly.

## Usage

```swift
RoomEntityFactory(
    bounds: bounds,
    doorways: doorways,
    spawnPoints: spawnPoints
).make(in: world)

// With an explicit room ID (for reconnecting rooms across sessions)
RoomEntityFactory(
    roomID: existingUUID,
    bounds: bounds
).make(in: world)
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `roomID` | `UUID?` | `nil` | Explicit room ID — a new UUID is generated if omitted |
| `bounds` | `RoomBounds` | — | Origin and size of the room in world space |
| `doorways` | `[Doorway]` | `[]` | Connection points to adjacent rooms |
| `spawnPoints` | `[SpawnPoint]` | `[]` | Enemy and item spawn locations |
| `useGrid` | `Bool` | `false` | Whether the room uses grid-based layout (reserved for future use) |

## Components Added

| Component | Initial Value |
|---|---|
| `RoomMetadataComponent` | `roomID`, `bounds`, `doorways`, `spawnPoints` |
| `TransformComponent` | `bounds.center` |
| `RoomMemberComponent` | `roomID` |
