import Foundation
import simd

/// Manages the logical state of locking and unlocking combat rooms by spawning barriers.
public final class RoomLockdownManager {
    
    public init() {}
    
    public func requiresLockdown(_ roomID: UUID, in world: World, builtRoomEntities: [UUID: Entity]) -> Bool {
        guard let roomEntity = builtRoomEntities[roomID] else { return false }
        return world.getComponent(type: CombatEncounterTag.self, for: roomEntity) != nil
    }

    public func unlockRoom(
        _ roomID: UUID,
        world: World,
        builtRoomEntities: [UUID: Entity],
        tileMapRenderer: (any TileMapRenderer)?
    ) {
        guard let roomEntity = builtRoomEntities[roomID] else { return }

        world.removeComponent(type: CombatEncounterTag.self, from: roomEntity)
        world.removeComponent(type: RoomInCombatTag.self, from: roomEntity)

        for entity in world.entities(with: BarrierTag.self) {
            guard let member = world.getComponent(type: RoomMemberComponent.self, for: entity),
                  member.roomID == roomID
            else { continue }
            world.destroyEntity(entity: entity)
        }

        tileMapRenderer?.tearDownBarriers(roomID: roomID)
    }

    public func lockRoom(
        _ roomID: UUID,
        world: World,
        graph: DungeonGraph?,
        theme: TileTheme,
        tileMapRenderer: (any TileMapRenderer)?,
        rng: SeededGenerator?
    ) {
        let doorways = graph?.doorways(for: roomID) ?? []
        for doorway in doorways {
            spawnBarrier(
                roomID: roomID,
                doorway: doorway,
                world: world,
                theme: theme,
                tileMapRenderer: tileMapRenderer,
                rng: rng
            )
        }
    }

    private func spawnBarrier(
        roomID: UUID,
        doorway: Doorway,
        world: World,
        theme: TileTheme,
        tileMapRenderer: (any TileMapRenderer)?,
        rng: SeededGenerator?
    ) {
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

        // 1. Visuals: Only render if renderer and RNG are both available.
        if let currentRNG = rng {
            var renderRNG = currentRNG
            tileMapRenderer?.renderBarrier(
                roomID: roomID,
                bounds: barrierBounds,
                side:   side,
                theme:  theme,
                using:  &renderRNG
            )
        }

        // 2. Physics: Create the collision barrier entity unconditionally.
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: barrierBounds.center), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: barrierBounds.size), to: entity)
        world.addComponent(component: BarrierTag(), to: entity)
        world.addComponent(component: WallTag(), to: entity)
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: entity)
    }
}
