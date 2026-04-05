import Foundation
import simd

/// Tag: Marks an entity as a wall
public struct WallTag: Component {}
 
/// Tag: Marks an entity as a floor tile
public struct FloorTag: Component {}
 
/// Tag: Marks an entity as an obstacle
public struct ObstacleTag: Component {}
 
/// Tag: Marks an entity as a door
public struct DoorTag: Component {
    public var direction: Direction
    
    public init(direction: Direction) {
        self.direction = direction
    }
}
 
/// Tag: Marks a door as locked
public struct LockedDoorTag: Component {}

/// Tag: Marks an entity as a barrier 
public struct BarrierTag: Component {}
