---
title: "Render System"
description: "How the RenderSystem works."
---

# Rendering System

The `RenderSystem` is how the entities in the **ECS World** (Logic) are rendered.

We use **SpriteKit** to render the entities, but the system itself has **no SpriteKit dependency** — it delegates all engine-specific work to a `RenderingBackend`. The SpriteKit implementation of that backend is `SpriteKitRenderingAdapter`.


**Components Required**:

For an entity to be rendered, it needs to have both a `TransformComponent` (position, scale, rotation) and a `SpriteComponent` (texture name, tint color).

**The Synchronization Loop**: 

Every frame, `RenderSystem.update()` performs a sync:

1. **Query** all entities with both `TransformComponent` and `SpriteComponent`.
2. **Create or update** each entity's node via `backend.syncNode(...)`.
3. **Remove** nodes for entities that are no longer renderable via `backend.removeNode(...)`.


### **RenderingBackend Protocol**:

`RenderSystem` depends on a protocol, not a concrete SpriteKit type. This means that we can swap out the rendering engine without changing the `RenderSystem`.

```swift
protocol RenderingBackend: AnyObject {
    func syncNode(for entity: Entity, transform: TransformComponent,
                  sprite: SpriteComponent, velocity: VelocityComponent?)
    func removeNode(for entity: Entity)
}
```

* **SpriteKitRenderingAdapter**: is the concrete SpriteKit implementation of `RenderingBackend`. It:
    - Keeps a private `nodeRegistry: [Entity: SKSpriteNode]` mapping each entity to its visual node.
    - Adds new nodes to **`worldLayer`** (not the scene root), so the `SpriteKitCameraAdapter` can shift the entire world layer to implement camera movement.
    - Handles flip direction based on `VelocityComponent`, tint color, and `zPosition`.

## SpriteComponent
 
`SpriteComponent` drives all visual configuration for an entity. It supports two rendering modes:
 
**Texture mode** — set `textureName` to an asset catalog name. The texture size drives the node size.
 
```swift
SpriteComponent(textureName: "knight")
```
 
**Colour mode** — leave `textureName` empty and provide a `renderSize`. Renders as a solid-colour rectangle. Used for map geometry (walls, floors).
 
```swift
// Use the built-in presets for map geometry:
SpriteComponent.wall(size: SIMD2<Float>(600, 16))
SpriteComponent.floor(size: SIMD2<Float>(600, 400))
```
 
### Z-Ordering
 
`SpriteComponent` has a `zPosition: CGFloat` field that maps directly to SpriteKit's `zPosition`. The established draw order is:
 
| Layer | `zPosition` | Examples |
|---|---|---|
| Floor | `0` | Floor fill |
| Walls / obstacles | `1` | Perimeter walls, rocks |
| Characters | `2` | Player, enemies (default for texture sprites) |
 
The presets `SpriteComponent.wall(size:)` and `SpriteComponent.floor(size:)` set `zPosition` automatically. The default `SpriteComponent(textureName:)` init defaults to `zPosition: 1` — override when needed.