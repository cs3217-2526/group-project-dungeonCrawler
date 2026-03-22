import Foundation

/// Reads the player's health and mana each frame and pushes the values to the HUD backend.
public final class HUDSystem: System {

    public let priority: Int = 95

    private weak var backend: HUDBackend?

    public init(backend: HUDBackend) {
        self.backend = backend
    }

    public func update(deltaTime: Double, world: World) {
        guard let backend,
              let player = world.entities(with: PlayerTagComponent.self).first
        else { return }

        if let health = world.getComponent(type: HealthComponent.self, for: player) {
            let maxHP = health.value.max ?? health.value.base
            backend.updateHealthBar(current: health.value.current, max: maxHP)
        }

        if let mana = world.getComponent(type: ManaComponent.self, for: player) {
            let maxMP = mana.value.max ?? mana.value.base
            backend.updateManaBar(current: mana.value.current, max: maxMP)
        }
    }
}
