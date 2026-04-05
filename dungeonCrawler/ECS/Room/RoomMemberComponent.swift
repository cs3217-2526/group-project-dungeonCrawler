import Foundation

/// Relationship component binding an entity to a specific room.
/// 
/// Attached to walls, floors, players, enemies, etc., to denote they belong 
/// to a specific `roomID`. Used for O(1) room-based cleanup 
/// and state management.
public struct RoomMemberComponent: Component {
    /// Matches `roomID` of the room this entity belongs to.
    public let roomID: UUID

    public init(roomID: UUID) {
        self.roomID = roomID
    }
}
