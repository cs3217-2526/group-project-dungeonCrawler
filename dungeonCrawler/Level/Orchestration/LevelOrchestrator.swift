import Foundation
import CoreGraphics
import simd

/// Orchestrates the ECS lifecycle of dungeon levels.
///
/// `LevelOrchestrator` acts as a facade, delegating generation to `LevelGenerationManager`
/// and state management to `RoomLockdownManager`.
public final class LevelOrchestrator {
    
    // MARK: - Dependencies
    public let layoutStrategy: any DungeonLayoutStrategy
    public let roomConstructor: any RoomConstructor
    public var tileMapRenderer: (any TileMapRenderer)?
    
    // MARK: - State
    private var currentTheme: TileTheme = .chilling
    private var builtRoomEntities: [UUID: Entity] = [:]
    private var currentGraph: DungeonGraph?
    private var currentRNG: SeededGenerator?
    
    private let lockdownManager: RoomLockdownManager

    public init(
        layoutStrategy: any DungeonLayoutStrategy,
        roomConstructor: any RoomConstructor
    ) {
        self.layoutStrategy = layoutStrategy
        self.roomConstructor = roomConstructor
        self.lockdownManager = RoomLockdownManager()
    }
    
    // MARK: - Level Loading
    
    public func loadLevel(_ levelNumber: Int, world: World) {
        tearDownAll(world: world)
        
        let generationManager = LevelGenerationManager(
            layoutStrategy: layoutStrategy,
            roomConstructor: roomConstructor,
            tileMapRenderer: tileMapRenderer,
            theme: currentTheme
        )
        
        // GenerationManager generates physical layout and assigns entities
        let (newGraph, newRNG) = generationManager.build(levelNumber: levelNumber, world: world)
        self.currentGraph = newGraph
        self.currentRNG = newRNG
        self.builtRoomEntities = generationManager.builtRoomEntities
    }
    
    // MARK: - Room Unlocking & Transitions (Delegated)
    
    public func roomEntity(for roomID: UUID) -> Entity? {
        builtRoomEntities[roomID]
    }
    
    public func requiresLockdown(_ roomID: UUID, in world: World) -> Bool {
        lockdownManager.requiresLockdown(roomID, in: world, builtRoomEntities: builtRoomEntities)
    }
    
    
    public func lockRoom(_ roomID: UUID, world: World) {
        // RNG is passed as a read-only copy for visual randomization
        lockdownManager.lockRoom(
            roomID,
            world: world,
            graph: currentGraph,
            theme: currentTheme,
            tileMapRenderer: tileMapRenderer,
            rng: currentRNG
        )
    }
    
    public func unlockRoom(_ roomID: UUID, world: World) {
        lockdownManager.unlockRoom(
            roomID,
            world: world,
            builtRoomEntities: builtRoomEntities,
            tileMapRenderer: tileMapRenderer
        )
    }
    
    // MARK: - Private Teardown
    
    private func tearDownAll(world: World) {
        // Destroy global level state
        for entity in world.entities(with: LevelStateComponent.self) {
            world.destroyEntity(entity: entity)
        }
        
        // Destroy all physical and visual entities
        for entity in world.entities(with: RoomMemberComponent.self) {
            world.destroyEntity(entity: entity)
        }
        
        builtRoomEntities.removeAll()
        currentGraph = nil
        tileMapRenderer?.tearDownAll()
    }
}
