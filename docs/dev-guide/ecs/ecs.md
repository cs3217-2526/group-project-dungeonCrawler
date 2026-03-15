---
title: "What is ECS?"
sidebar_position: 1
---

# Entity-Component-System (ECS)

The game is built on an **Entity-Component-System (ECS)** architecture — a pattern common in game development that prioritises composition over inheritance.

## Core Concepts

### Entity
An entity is simply a unique ID. It has no data or behaviour of its own — it is just an identifier that ties components together.

### Component
A component is a plain data container attached to an entity. It holds state but no logic. Examples:

- `PositionComponent` — stores x/y coordinates
- `HealthComponent` — stores current and max HP
- `VelocityComponent` — stores movement vector

### System
A system contains the logic. Each frame, a system queries for entities that have the relevant components and processes them. Examples:

- `MovementSystem` — reads `VelocityComponent`, writes `PositionComponent`
- `RenderSystem` — reads `PositionComponent`, draws the entity on screen
- `CombatSystem` — reads `HealthComponent`, applies damage

## Why ECS?

| Approach | Problem |
|---|---|
| Deep inheritance | Fragile, hard to mix behaviours |
| ECS composition | Add/remove components freely at runtime |

ECS makes it easy to add new behaviours (e.g. a "poisoned" status) by simply attaching a new component, without touching existing classes.

## Project Structure

```
Sources/
  ECS/
    Entity.swift       — Entity ID type
    Component.swift    — Component protocol
    System.swift       — System protocol
    World.swift        — Manages entities, components, and systems
```
