import Foundation
import CoreGraphics
import simd

/// Orchestrates the ECS lifecycle of dungeon levels.
///
/// `LevelOrchestrator` is a **service**, not an ECS `System`. It handles
/// the heavy imperative events: level loading and atomical room transitions.
public final class LevelOrchestrator {

    // MARK: - Strategy dependencies (injected, swappable)

    public var layoutStrategy: any DungeonLayoutStrategy
    public var roomConstructor: any RoomConstructor
    /// Optional visual tile renderer. When set, room/corridor tile maps are painted
    /// at build time and torn down on level reset.
    public var tileMapRenderer: (any TileMapRenderer)?

    // MARK: - State

    private var currentTheme: TileTheme = .chilling
    /// Maps `RoomSpecification.id` → the ECS entity created for that room.
    private var builtRoomEntities: [UUID: Entity] = [:]
    private var currentRNG: SeededGenerator?

    // MARK: - Init

    public init(
        layoutStrategy: any DungeonLayoutStrategy,
        roomConstructor: any RoomConstructor
    ) {
        self.layoutStrategy  = layoutStrategy
        self.roomConstructor = roomConstructor
    }

    // MARK: - Level Loading

    /// Destroys all entities from any previous level, generates a new `DungeonGraph`,
    /// builds every room and corridor, then positions the player in the start room.
    public func loadLevel(_ levelNumber: Int, world: World) {
        // Tear down everything from the prior level
        tearDownAll(world: world)

        // Generate graph
        let context = GenerationContext(floorIndex: levelNumber)
        self.currentRNG = context.makeGenerator()
        
        let newGraph = layoutStrategy.generate(context: context)

        // Build ALL rooms at once so they are all visible from the start
        for specification in newGraph.allSpecifications {
            buildRoom(specification: specification, graph: newGraph, world: world)
        }

        // Build corridors for each unique edge pair (only forward edges to avoid duplication)
        for edge in newGraph.allEdges {
            guard let fromSpec = newGraph.specification(for: edge.fromNodeID),
                  let toSpec   = newGraph.specification(for: edge.toNodeID)
            else { continue }
            
            if edge.fromNodeID.uuidString < edge.toNodeID.uuidString {
                buildCorridor(edge: edge, from: fromSpec, to: toSpec, world: world)
            }
        }

        // Activate the start room and place the player
        guard let startSpec = newGraph.specification(for: newGraph.startNodeID) else { return }
        
        // Setup Global Level State
        let stateEntity = world.createEntity()
        world.addComponent(component: LevelStateComponent(graph: newGraph, activeNodeID: startSpec.id), to: stateEntity)

        positionPlayer(
            at: startSpec.bounds.center,
            world: world
        )
    }

    // MARK: - Transition

    /// Updates the active room ID when the player walks into a neighbouring room.
    public func transition(to nodeID: UUID, world: World) {
        guard let stateEntity = world.entities(with: LevelStateComponent.self).first else { return }
        
        world.modifyComponentIfExist(type: LevelStateComponent.self, for: stateEntity) { state in
            state.activeNodeID = nodeID
            state.transitionCooldown = WorldConstants.transitionCooldown
        }
    }

    // MARK: - Private — Room Lifecycle

    private func buildRoom(specification: RoomSpecification, graph: DungeonGraph, world: World) {
        guard var rng = currentRNG else { return }

        let doorways   = graph.doorways(for: specification.id)
        let roomEntity = RoomEntityFactory(
            roomID: specification.id,
            bounds: specification.bounds,
            doorways: doorways
        ).make(in: world)

        let builder = RoomBuilder(
            world: world,
            bounds: specification.bounds,
            roomID: specification.id,
            renderVisualSprites: tileMapRenderer == nil
        )

        roomConstructor.construct(
            builder: builder,
            specification: specification,
            doorways: doorways,
            using: &rng
        )

        let scale = WorldConstants.standardEntityScale
        var populateContext = PopulateContext(
            world: world,
            bounds: specification.bounds,
            scale: scale,
            roomID: specification.id,
            generator: rng,
            structuralBounds: builder.structuralBounds
        )
        
        specification.populator.populate(context: &populateContext)
        self.currentRNG = populateContext.generator
        builtRoomEntities[specification.id] = roomEntity

        tileMapRenderer?.renderRoom(
            roomID: specification.id,
            bounds: specification.bounds,
            doorways: doorways,
            theme: currentTheme,
            using: &rng
        )

        world.addComponent(component: RoomLockedTag(), to: roomEntity)
        if !specification.isStartRoom {
            world.addComponent(component: RoomInCombatTag(), to: roomEntity)
        }
    }

    /// Destroys ALL room-owned entities across the entire world (used on level reload).
    private func tearDownAll(world: World) {
        // Destroy level state
        for entity in world.entities(with: LevelStateComponent.self) {
            world.destroyEntity(entity: entity)
        }
        
        // Destroy all members
        for entity in world.entities(with: RoomMemberComponent.self) {
            world.destroyEntity(entity: entity)
        }
        
        builtRoomEntities.removeAll()
        tileMapRenderer?.tearDownAll()
    }

    // MARK: - Private — Player Positioning

    private func positionPlayer(at position: SIMD2<Float>, world: World) {
        if let player = world.entities(with: PlayerTagComponent.self).first {
            world.modifyComponentIfExist(type: TransformComponent.self, for: player) { t in
                t.position = position
            }
        } else {
            let scaleForPlayer  = WorldConstants.standardEntityScale
            let player = PlayerEntityFactory(at: position, scale: scaleForPlayer).make(in: world)
            guard
                let handgunDefinition = WeaponLibrary.definition(for: "handgun"),
                let swordDefinition = WeaponLibrary.definition(for: "sword")
            else {
                fatalError("Missing built-in starter weapon definitions")
            }
            let handgun = WeaponEntityFactory(
                player: player,
                textureName: handgunDefinition.textureName,
                offset: handgunDefinition.offset,
                scale: handgunDefinition.scale,
                lastFiredAt: 0,
                coolDownIntervel: handgunDefinition.cooldown,
                attackSpeed: handgunDefinition.attackSpeed,
                effects: WeaponEffectFactory.makeEffects(from: handgunDefinition),
                anchorPoint: handgunDefinition.anchorPoint,
                initRotation: handgunDefinition.initRotation,
                initLocation: nil
            ).make(in: world)
            let sword = WeaponEntityFactory(
                player: player,
                textureName: swordDefinition.textureName,
                offset: swordDefinition.offset,
                scale: swordDefinition.scale,
                coolDownIntervel: swordDefinition.cooldown,
                attackSpeed: swordDefinition.attackSpeed,
                effects: WeaponEffectFactory.makeEffects(from: swordDefinition),
                anchorPoint: swordDefinition.anchorPoint,
                initRotation: swordDefinition.initRotation,
                initLocation: nil
            ).make(in: world)
            world.addComponent(
                component: SpriteComponent(
                    content: .texture(name: handgunDefinition.textureName),
                    layer: .weapon,
                    anchorPoint: handgunDefinition.anchorPoint ?? SIMD2<Float>(0.5, 0.5)),
                to: handgun)
            world.addComponent(
                component: EquippedWeaponComponent(primaryWeapon: handgun, secondaryWeapon: sword),
                to: player
            )
        }
    }

    // MARK: - Private — Geometry Helpers

    private func entryPoint(direction: Direction, bounds: RoomBounds) -> SIMD2<Float> {
        let inset = WorldConstants.roomEntryInset
        switch direction {
        case .east:  return SIMD2(bounds.maxX - inset, bounds.center.y)
        case .west:  return SIMD2(bounds.minX + inset, bounds.center.y)
        case .north: return SIMD2(bounds.center.x, bounds.maxY - inset)
        case .south: return SIMD2(bounds.center.x, bounds.minY + inset)
        }
    }

    private func buildCorridor(edge: DungeonEdge, from fromSpec: RoomSpecification, to toSpec: RoomSpecification, world: World) {
        guard var rng = currentRNG else { return }
        
        let wallThickness = WorldConstants.wallThickness
        let width = edge.corridor.width
        var corridorBounds: RoomBounds?
        var structuralBounds: [(center: SIMD2<Float>, size: SIMD2<Float>)] = []

        switch edge.exitDirection {
        case .east:
            let x0 = fromSpec.bounds.maxX
            let x1 = toSpec.bounds.minX
            let corridorLen = x1 - x0
            guard corridorLen > 0 else { return }
            let midX = (x0 + x1) / 2
            let midY = fromSpec.bounds.center.y

            let bounds = RoomBounds(
                origin: SIMD2(x0, midY - width / 2),
                size:   SIMD2(corridorLen, width)
            )
            corridorBounds = bounds

            makeCorridorEntity(position: bounds.center, size: bounds.size, isWall: false, roomID: fromSpec.id, world: world)
            
            let t = wallThickness
            let wall1Pos = SIMD2(midX, midY + width / 2 + t / 2)
            let wall1Size = SIMD2(corridorLen, t)
            makeCorridorEntity(position: wall1Pos, size: wall1Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall1Pos, size: wall1Size))
            
            let wall2Pos = SIMD2(midX, midY - width / 2 - t / 2)
            let wall2Size = SIMD2(corridorLen, t)
            makeCorridorEntity(position: wall2Pos, size: wall2Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall2Pos, size: wall2Size))

            tileMapRenderer?.renderCorridor(
                roomID: fromSpec.id,
                bounds: RoomBounds(origin: SIMD2(x0, midY - width / 2 - t), size: SIMD2(corridorLen, width + t * 4)),
                axis: .horizontal,
                theme: currentTheme,
                using: &rng
            )

        case .west:
            let x0 = toSpec.bounds.maxX
            let x1 = fromSpec.bounds.minX
            let corridorLen = x1 - x0
            guard corridorLen > 0 else { return }
            let midX = (x0 + x1) / 2
            let midY = fromSpec.bounds.center.y

            let bounds = RoomBounds(origin: SIMD2(x0, midY - width / 2), size: SIMD2(corridorLen, width))
            corridorBounds = bounds

            makeCorridorEntity(position: bounds.center, size: bounds.size, isWall: false, roomID: fromSpec.id, world: world)
            
            let t = wallThickness
            let wall1Pos = SIMD2(midX, midY + width / 2 + t / 2)
            let wall1Size = SIMD2(corridorLen, t)
            makeCorridorEntity(position: wall1Pos, size: wall1Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall1Pos, size: wall1Size))
            
            let wall2Pos = SIMD2(midX, midY - width / 2 - t / 2)
            let wall2Size = SIMD2(corridorLen, t)
            makeCorridorEntity(position: wall2Pos, size: wall2Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall2Pos, size: wall2Size))

            tileMapRenderer?.renderCorridor(
                roomID: fromSpec.id,
                bounds: RoomBounds(origin: SIMD2(x0, midY - width / 2 - t), size: SIMD2(corridorLen, width + t * 4)),
                axis: .horizontal,
                theme: currentTheme,
                using: &rng
            )

        case .north:
            let y0 = fromSpec.bounds.maxY
            let y1 = toSpec.bounds.minY
            let corridorLen = y1 - y0
            guard corridorLen > 0 else { return }
            let midX = fromSpec.bounds.center.x
            let midY = (y0 + y1) / 2

            let bounds = RoomBounds(origin: SIMD2(midX - width / 2, y0), size: SIMD2(width, corridorLen))
            corridorBounds = bounds

            makeCorridorEntity(position: bounds.center, size: bounds.size, isWall: false, roomID: fromSpec.id, world: world)
            
            let t = wallThickness
            let wall1Pos = SIMD2(midX + width / 2 + t / 2, midY)
            let wall1Size = SIMD2(t, corridorLen)
            makeCorridorEntity(position: wall1Pos, size: wall1Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall1Pos, size: wall1Size))
            
            let wall2Pos = SIMD2(midX - width / 2 - t / 2, midY)
            let wall2Size = SIMD2(t, corridorLen)
            makeCorridorEntity(position: wall2Pos, size: wall2Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall2Pos, size: wall2Size))

            tileMapRenderer?.renderCorridor(
                roomID: fromSpec.id,
                bounds: RoomBounds(origin: SIMD2(midX - width / 2 - t, y0), size: SIMD2(width + t * 2, corridorLen)),
                axis: .vertical,
                theme: currentTheme,
                using: &rng
            )

        case .south:
            let y0 = toSpec.bounds.maxY
            let y1 = fromSpec.bounds.minY
            let corridorLen = y1 - y0
            guard corridorLen > 0 else { return }
            let midX = fromSpec.bounds.center.x
            let midY = (y0 + y1) / 2

            let bounds = RoomBounds(origin: SIMD2(midX - width / 2, y0), size: SIMD2(width, corridorLen))
            corridorBounds = bounds

            makeCorridorEntity(position: bounds.center, size: bounds.size, isWall: false, roomID: fromSpec.id, world: world)
            
            let t = wallThickness
            let wall1Pos = SIMD2(midX + width / 2 + t / 2, midY)
            let wall1Size = SIMD2(t, corridorLen)
            makeCorridorEntity(position: wall1Pos, size: wall1Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall1Pos, size: wall1Size))
            
            let wall2Pos = SIMD2(midX - width / 2 - t / 2, midY)
            let wall2Size = SIMD2(t, corridorLen)
            makeCorridorEntity(position: wall2Pos, size: wall2Size, isWall: true, roomID: fromSpec.id, world: world)
            structuralBounds.append((center: wall2Pos, size: wall2Size))

            tileMapRenderer?.renderCorridor(
                roomID: fromSpec.id,
                bounds: RoomBounds(origin: SIMD2(midX - width / 2 - t, y0), size: SIMD2(width + t * 2, corridorLen)),
                axis: .vertical,
                theme: currentTheme,
                using: &rng
            )
        }

        if let corridorBounds {
            var populateContext = PopulateContext(
                world: world,
                bounds: corridorBounds,
                scale: WorldConstants.standardEntityScale,
                roomID: fromSpec.id,
                generator: rng,
                structuralBounds: structuralBounds
            )
            
            edge.corridor.populator.populate(context: &populateContext)
            self.currentRNG = populateContext.generator
        }
    }

    private func makeCorridorEntity(
        position: SIMD2<Float>,
        size: SIMD2<Float>,
        isWall: Bool,
        roomID: UUID,
        world: World
    ) {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        let renderSprites = tileMapRenderer == nil
        if isWall {
            world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
            if renderSprites {
                world.addComponent(component: SpriteComponent.wall(size: size), to: entity)
            }
            world.addComponent(component: WallTag(), to: entity)
        } else {
            if renderSprites {
                world.addComponent(component: SpriteComponent.floor(size: size), to: entity)
            }
            world.addComponent(component: FloorTag(), to: entity)
        }
        world.addComponent(component: RoomMemberComponent(roomID: roomID), to: entity)
    }
}
