---
description: "How the CameraSystem works."
---

# Camera System & Viewport

This document explains how the camera works and how it follows characters in the world. Conceptual ideas:

* Camera is an entity that has a `ViewportComponent`.
* `CameraFocusComponent` stays on the **player entity** and marks what the camera should follow. The camera entity itself only carries `ViewportComponent`. (We can improve this later on)


## CameraSystem and ViewportComponent 

`CameraSystem` writes to a plain `ViewportComponent` attached to a dedicated camera entity. This entity only carries `ViewportComponent` (as of now, future components could be like `ScreenShakeComponent`, handled by `ScreenShakeSystem` for example)
* `CameraSystem` performs the focusing math (where to shift the camera to, how fast) and writes the result into `ViewportComponent`. It has no knowledge of SpriteKit.

```swift
// Pure ECS data — engine-agnostic
struct ViewportComponent: Component {
    var position: SIMD2<Float>
    var zoom: Float = 1.0
    var rotation: Float = 0.0
}
```

Here, naturally, the position, zoom and rotation are referring to that of the camera.
* The position is storing where in the world that we want to look at.



**Adapter Pattern for SpriteKit**

Spritekit-specific code lives in a **adapter layer** outside the ECS. This means:

- Swapping SpriteKit for another renderer = replace the adapter, not the systems.
- Camera logic (lerp, follow, zoom) stays testable without any engine dependency.
- The same `CameraSystem` works regardless of how the viewport is ultimately rendered.


## SpriteKitCameraAdapter

`SpriteKitCameraAdapter` is a helper owned by `GameScene` that reads `ViewportComponent` each frame and applies it to SpriteKit. Instead of moving a camera node, we move the entire game world in the opposite direction:

**The two-layer scene structure:**

```text
Scene
├── uiLayer (Static — joysticks, HUD, menus)
└── worldLayer (Moving — player, enemies, map)
```

* If character moves **Right (+X)**, `worldLayer` moves to the **Left (-X)**.
* The UI layer never needs to move as it is a **sibling** of `worldLayer`, not a child of it.
* `GameScene` calls `cameraAdapter.apply(viewport:screenCenter:)` at the end of each `update()` frame, after `systemManager.update(...)` has run.


