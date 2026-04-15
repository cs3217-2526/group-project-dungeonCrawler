import Foundation

/// Static registry of all playable dungeons. Add new entries here to expose
/// them in the level-select screen — no other files need to change.
public enum DungeonLibrary {

    public static let all: [DungeonDefinition] = [
        DungeonDefinition(
            name: "Chilling Crypts",
            description: "A frozen labyrinth of ancient crypts.\nNavigate a straight path through icy chambers.",
            theme: .chilling,
            layoutStrategy: LinearDungeonLayout(
                roomCount: 3,
                enemyPool: [.ranger, .tower]
            )
        ),
        DungeonDefinition(
            name: "Burning Depths",
            description: "A scorched hub of fire and brimstone.\nRooms radiate outward in every direction.",
            theme: .burning,
            layoutStrategy: StarDungeonLayout(
                enemyPool: [.charger, .mummy, .ranger]
            )
        ),
        DungeonDefinition(
            name: "Living Labyrinth",
            description: "A twisting organic maze.\nFollow a winding L-shaped path to the boss.",
            theme: .living,
            layoutStrategy: LShapeDungeonLayout(
                enemyPool: [.charger, .mummy, .ranger]
            )
        ),
    ]
}
