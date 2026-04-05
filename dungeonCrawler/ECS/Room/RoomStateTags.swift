import Foundation

/// Tag: Room entrance is locked, preventing player from leaving
public struct RoomLockedTag: Component {}
 
/// Tag: Room is currently in combat (enemies active)
public struct RoomInCombatTag: Component {}
 
/// Tag: Room has been cleared of all enemies
public struct RoomClearedTag: Component {}

/// Tag: Room has been visited by the player at least once
public struct RoomVisitedTag: Component {}
