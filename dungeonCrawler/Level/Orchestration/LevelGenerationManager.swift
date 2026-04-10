import Foundation
import CoreGraphics
import simd

/// Responsible for generating the physical layout, instantiating ECS entities for rooms
/// and corridors, and positioning the player.
public final class LevelGenerationManager {
    private let layoutStrategy: any DungeonLayoutStrategy
    private let roomConstructor: any RoomConstructor
    private let tileMapRenderer: (any TileMapRenderer)?
    private let theme: TileTheme
    private var rng: SeededGenerator?

    public private(set) var builtRoomEntities: [UUID: Entity] = [:]
    
    public init(
        layoutStrategy: any DungeonLayoutStrategy,
        roomConstructor: any RoomConstructor,
        tileMapRenderer: (any TileMapRenderer)?,
        theme: TileTheme
    ) {
        self.layoutStrategy = layoutStrategy
        self.roomConstructor = roomConstructor
        self.tileMapRenderer = tileMapRenderer
        self.theme = theme
    }
    
    public func build(levelNumber: Int, world: World) -> (DungeonGraph, SeededGenerator?) {
        let context = GenerationContext(floorIndex: levelNumber)
        let generator = context.makeGenerator()
        self.rng = generator
        
        let newGraph = layoutStrategy.generate(context: context)
        
        for specification in newGraph.allSpecifications {
            buildRoom(specification: specification, graph: newGraph, world: world)
        }
        
        for edge in newGraph.allEdges {
            guard let fromSpec = newGraph.specification(for: edge.fromNodeID),
                  let toSpec   = newGraph.specification(for: edge.toNodeID)
            else { continue }
            
            if edge.fromNodeID.uuidString < edge.toNodeID.uuidString {
                buildCorridor(edge: edge, from: fromSpec, to: toSpec, world: world)
            }
        }
        
        if let startSpec = newGraph.specification(for: newGraph.startNodeID) {
            let stateEntity = world.createEntity()
            world.addComponent(component: LevelStateComponent(graph: newGraph, activeNodeID: startSpec.id), to: stateEntity)
            positionPlayer(at: startSpec.bounds.center, world: world)
        }
        
        return (newGraph, self.rng)
    }
    
    private func buildRoom(specification: RoomSpecification, graph: DungeonGraph, world: World) {
        guard var currentRNG = rng else { return }

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
            using: &currentRNG
        )

        let scale = WorldConstants.standardEntityScale
        var populateContext = PopulateContext(
            world: world,
            bounds: specification.bounds,
            scale: scale,
            roomID: specification.id,
            generator: currentRNG,
            structuralBounds: builder.structuralBounds
        )
        
        specification.populator.populate(context: &populateContext)
        self.rng = populateContext.generator
        builtRoomEntities[specification.id] = roomEntity

        tileMapRenderer?.renderRoom(
            roomID: specification.id,
            bounds: specification.bounds,
            doorways: doorways,
            theme: theme,
            using: &currentRNG
        )

        if !specification.isStartRoom && specification.populator.requiresCombatEncounter {
            world.addComponent(component: CombatEncounterTag(), to: roomEntity)
            world.addComponent(component: RoomInCombatTag(),    to: roomEntity)
        }
    }

    private func positionPlayer(at position: SIMD2<Float>, world: World) {
        if let player = world.entities(with: PlayerTagComponent.self).first {
            world.getComponent(type: TransformComponent.self, for: player)?.position = position
        } else {
            let scaleForPlayer  = WorldConstants.standardEntityScale
            let player = PlayerEntityFactory(at: position, scale: scaleForPlayer).make(in: world)
            let handgunDefinition = WeaponType.handgun.baseDefinition
            let swordDefinition = WeaponType.sword.baseDefinition
            let handgun = WeaponEntityFactory(base: handgunDefinition).make(in: world, player: player)
            let sword = WeaponEntityFactory(base: swordDefinition).make(in: world, player: player)
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

    private func buildCorridor(edge: DungeonEdge, from fromSpec: RoomSpecification, to toSpec: RoomSpecification, world: World) {
        guard var currentRNG = rng else { return }
        
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
                theme: theme,
                using: &currentRNG
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
                theme: theme,
                using: &currentRNG
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
                theme: theme,
                using: &currentRNG
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
                theme: theme,
                using: &currentRNG
            )
        }

        if let corridorBounds {
            var populateContext = PopulateContext(
                world: world,
                bounds: corridorBounds,
                scale: WorldConstants.standardEntityScale,
                roomID: fromSpec.id,
                generator: currentRNG,
                structuralBounds: structuralBounds
            )
            
            edge.corridor.populator.populate(context: &populateContext)
            self.rng = populateContext.generator
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
