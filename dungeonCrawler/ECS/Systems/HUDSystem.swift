import Foundation

/// Reads the player's health and mana each frame and pushes the values to the HUD backend.
/// Dequeues JoystickRenderCommands to update the joystick backend.
public final class HUDSystem: System {

    public var dependencies: [System.Type] { [HealthSystem.self] }

    private weak var backend: HUDBackend?
    private weak var joystickBackend: JoystickBackend?
    private let commandQueues: CommandQueues

    public init(backend: HUDBackend, joystickBackend: JoystickBackend? = nil, commandQueues: CommandQueues) {
        self.backend = backend
        self.joystickBackend = joystickBackend
        self.commandQueues = commandQueues
    }

    public func update(deltaTime: Double, world: World) {
        updateStats(world: world)
        updateJoysticks()
    }

    private func updateStats(world: World) {
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

    private func updateJoysticks() {
        guard let joystickBackend else { return }

        var latest: JoystickRenderCommand?
        while let cmd = commandQueues.pop(JoystickRenderCommand.self) {
            latest = cmd
        }

        guard let cmd = latest else { return }
        joystickBackend.updateJoystickBase(side: .left, position: cmd.leftBase)
        joystickBackend.updateJoystickHandle(side: .left, position: cmd.leftHandle)
        joystickBackend.updateJoystickBase(side: .right, position: cmd.rightBase)
        joystickBackend.updateJoystickHandle(side: .right, position: cmd.rightHandle)
    }
}
