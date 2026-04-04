import Foundation

public struct WeaponRoomPopulator: RoomPopulatorStrategy {

    public func populate(context: inout PopulateContext) {
        guard let position = context.findEmptySpace() else { return }
        context.spawnWeapon(at: position)
    }
}

