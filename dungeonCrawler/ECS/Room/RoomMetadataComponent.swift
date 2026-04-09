import Foundation
import simd

/// The "Blueprint Data" for a specific room entity.
/// 
/// Attached only to the abstract "Room Entity" that represents the whole room.
public class RoomMetadataComponent: Component {
    public let roomID: UUID
    public var bounds: RoomBounds
    public var doorways: [Doorway]
    public var spawnPoints: [SpawnPoint]

    public init(
        roomID: UUID = UUID(),
        bounds: RoomBounds,
        doorways: [Doorway] = [],
        spawnPoints: [SpawnPoint] = []
    ) {
        self.roomID      = roomID
        self.bounds      = bounds
        self.doorways    = doorways
        self.spawnPoints = spawnPoints
    }
}
