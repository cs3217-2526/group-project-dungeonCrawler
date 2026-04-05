import Foundation
import simd

/// Manages the logical state of room transitions, locking combat rooms, and spawning barriers.
public final class LevelTransitionManager {
    
    private var pendingLockdowns: [UUID: SIMD2<Float>] = [:]
    
    public init() {}
    
    public func clearPending() {
        pendingLockdowns.removeAll()
    }
    
    public func transition(
        to nodeID: UUID,
        playerPos: SIMD2<Float>,
        world: World,
        builtRoomEntities: [UUID: Entity]
    ) {
        guard let stateEntity = world.entities(with: LevelStateComponent.self).first else { return }

        world.modifyComponentIfExist(type: LevelStateComponent.self, for: stateEntity) { state in
            state.activeNodeID = nodeID
        }

        // Cancel any other pending lockdowns when entering a new room.
        // A player is only ever "entering" one room at a time.
        pendingLockdowns.removeAll()

        guard let roomEntity = builtRoomEntities[nodeID],
              world.getComponent(type: RoomInCombatTag.self, for: roomEntity) != nil
        else { return }

        let alreadySpawned = world.entities(with: BarrierTag.self).contains { entity in
            world.getComponent(type: RoomMemberComponent.self, for: entity)?.roomID == nodeID
        }
        guard !alreadySpawned else { return }

        // Start tracking the entry point for this newly entered room.
        pendingLockdowns[nodeID] = playerPos
    }

    public func isRoomLocked(_ roomID: UUID, in world: World, builtRoomEntities: [UUID: Entity]) -> Bool {
        guard let roomEntity = builtRoomEntities[roomID] else { return false }
        return world.getComponent(type: RoomLockedTag.self, for: roomEntity) != nil
    }

    public func unlockRoom(
        _ roomID: UUID,
        world: World,
        builtRoomEntities: [UUID: Entity],
        tileMapRenderer: (any TileMapRenderer)?
    ) {
        guard let roomEntity = builtRoomEntities[roomID] else { return }

        world.removeComponent(type: RoomLockedTag.self,   from: roomEntity)
        world.removeComponent(type: RoomInCombatTag.self, from: roomEntity)

        for entity in world.entities(with: BarrierTag.self) {
            guard let member = world.getComponent(type: RoomMemberComponent.self, for: entity),
                  member.roomID == roomID
            else { continue }
            world.destroyEntity(entity: entity)
        }

        tileMapRenderer?.tearDownBarriers(roomID: roomID)
    }

    public func processPendingRoomLockdowns(
        playerPos: SIMD2<Float>,
        world: World,
        graph: DungeonGraph?,
        theme: TileTheme,
        tileMapRenderer: (any TileMapRenderer)?,
        rng: inout SeededGenerator?
    ) {
        guard !pendingLockdowns.isEmpty else { return }
        let inset = WorldConstants.roomEntryInset

        var toSpawn: [UUID] = []
        for (roomID, entryPos) in pendingLockdowns {
            guard let spec = graph?.specification(for: roomID) else { continue }
            
            let dist = simd_distance(playerPos, entryPos)
            let isInside = spec.bounds.contains(playerPos)
            
            if isInside && dist >= inset {
                toSpawn.append(roomID)
            }
        }
        for roomID in toSpawn {
            pendingLockdowns.removeValue(forKey: roomID)
            let doorways = graph?.doorways(for: roomID) ?? []
            for doorway in doorways {
                spawnBarrier(
                    roomID: roomID,
                    doorway: doorway,
                    world: world,
                    theme: theme,
                    tileMapRenderer: tileMapRenderer,
                    rng: &rng
                )
            }
        }
    }

    private func spawnBarrier(
        roomID: UUID,
        doorway: Doorway,
        world: World,
        theme: TileTheme,
        tileMapRenderer: (any TileMapRenderer)?,
        rng: inout SeededGenerator?
    ) {
        guard var currentRNG = rng else { return }
        let t = WorldConstants.tileSize
        let w = doorway.width

        let barrierBounds: RoomBounds
        let side: BarrierSide

        switch doorway.direction {
        case .east:
            barrierBounds = RoomBounds(
                origin: SIMD2(doorway.position.x - t, doorway.position.y - w / 2),
                size:   SIMD2(t, w)
            )
            side = .right
        case .west:
            barrierBounds = RoomBounds(
                origin: SIMD2(doorway.position.x, doorway.position.y - w / 2),
                size:   SIMD2(t, w)
            )
            side = .left
        case .north:
            barrierBounds = RoomBounds(
                origin: SIMD2(doorway.position.x - w / 2, doorway.position.y - 4 * t),
                size:   SIMD2(w, 4 * t)
            )
            side = .top
        case .south:
            barrierBounds = RoomBounds(
                origin: SIMD2(doorway.position.x - w / 2, doorway.position.y),
                size:   SIMD2(w, 4 * t)
            )
            side = .bottom
        }

        tileMapRenderer?.renderBarrier(
            roomID: roomID,
            bounds: barrierBounds,
            side:   side,
            theme:  theme,
            using:  &currentRNG
        )
        rng = currentRNG

        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: barrierBounds.center), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: barrierBounds.size), to: entity)
        world.addComponent(component: BarrierTag(), to: entity)
        world.addComponent(component: WallTag(), to: entity)
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: entity)
    }
}
