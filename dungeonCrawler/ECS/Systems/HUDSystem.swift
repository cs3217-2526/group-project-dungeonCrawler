import Foundation

/// Reads the player's health, mana, and equipped weapon ammo each frame
/// and pushes the values to the HUD backend.
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

    // MARK: - Stats

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

        updateAmmo(player: player, world: world, backend: backend)
        updateCharge(player: player, world: world, backend: backend)
    }

    private func updateCharge(player: Entity, world: World, backend: HUDBackend) {
        guard let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: player),
              let charge = world.getComponent(type: WeaponChargeComponent.self, for: equipped.primaryWeapon),
              charge.required > 0 else {
            backend.hideChargeBar()
            return
        }

        backend.updateChargeBar(progress: charge.elapsed / charge.required)
    }

    // MARK: - Ammo

    /// Reads ammo state from the player's primary weapon.
    /// Shows the ammo bar only when a firearm (WeaponAmmoComponent) is equipped.
    /// Hides the bar for melee and magical weapons.
    private func updateAmmo(player: Entity, world: World, backend: HUDBackend) {
        guard let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: player) else {
            backend.hideAmmoBar()
            return
        }

        let primaryWeapon = equipped.primaryWeapon

        guard let ammo = world.getComponent(type: WeaponAmmoComponent.self, for: primaryWeapon) else {
            // Primary weapon is melee or magical — no ammo bar needed.
            backend.hideAmmoBar()
            return
        }

        backend.updateAmmoBar(
            current: ammo.currentAmmo,
            max: ammo.magazineSize,
            isReloading: ammo.isReloading,
            reloadProgress: ammo.reloadProgress
        )
    }

    // MARK: - Joysticks

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
