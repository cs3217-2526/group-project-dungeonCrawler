import Foundation

public struct WeaponRoomPopulator: RoomPopulatorStrategy {
    public var requiresCombatEncounter: Bool { false }

    public init() {}

    public func populate(context: inout PopulateContext) {
        guard let position = context.findEmptySpace() else { return }
        context.spawnWeapon(at: position)
    }
}

