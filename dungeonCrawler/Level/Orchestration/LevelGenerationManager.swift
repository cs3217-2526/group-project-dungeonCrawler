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

        if specification.isBoss {
            world.addComponent(component: BossRoomTag(), to: roomEntity)
        }

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
                    layer: .weaponFront,
                    anchorPoint: handgunDefinition.anchorPoint ?? SIMD2<Float>(0.5, 0.5)),
                to: handgun)
            world.addComponent(
                component: EquippedWeaponComponent(primaryWeapon: handgun, secondaryWeapon: sword),
                to: player
            )
        }
    }

    private struct CorridorGeometry {
        let bounds: RoomBounds
        let walls: [(center: SIMD2<Float>, size: SIMD2<Float>)]
        let renderBounds: RoomBounds
        let axis: CorridorAxis
    }

    private func corridorGeometry(
        for edge: DungeonEdge,
        from fromSpec: RoomSpecification,
        to toSpec: RoomSpecification
    ) -> CorridorGeometry? {
        let t = WorldConstants.wallThickness
        let width = edge.corridor.width

        switch edge.exitDirection {
        case .east:
            return horizontalCorridorGeometry(
                x0: fromSpec.bounds.maxX, x1: toSpec.bounds.minX,
                midY: fromSpec.bounds.center.y, width: width, t: t)
        case .west:
            return horizontalCorridorGeometry(
                x0: toSpec.bounds.maxX, x1: fromSpec.bounds.minX,
                midY: fromSpec.bounds.center.y, width: width, t: t)
        case .north:
            let y0 = fromSpec.bounds.maxY, y1 = toSpec.bounds.minY
            guard y1 - y0 > 0 else { return nil }
            let midX = fromSpec.bounds.center.x
            let wallStartY = y0 - WorldConstants.northCorridorFrameDepth
            return verticalCorridorGeometry(
                y0: y0, y1: y1, midX: midX, width: width, t: t,
                sideWallStartY: wallStartY, sideWallEndY: y1)
        case .south:
            let y0 = toSpec.bounds.maxY, y1 = fromSpec.bounds.minY
            guard y1 - y0 > 0 else { return nil }
            let midX = fromSpec.bounds.center.x
            return verticalCorridorGeometry(
                y0: y0, y1: y1, midX: midX, width: width, t: t,
                sideWallStartY: y0, sideWallEndY: y1 + t)
        }
    }

    private func horizontalCorridorGeometry(
        x0: Float, x1: Float, midY: Float, width: Float, t: Float
    ) -> CorridorGeometry? {
        let len = x1 - x0
        guard len > 0 else { return nil }
        let midX = (x0 + x1) / 2
        let bounds = RoomBounds(origin: SIMD2(x0, midY - width / 2), size: SIMD2(len, width))
        return CorridorGeometry(
            bounds: bounds,
            walls: [
                (center: SIMD2(midX, midY + width / 2 + t / 2), size: SIMD2(len, t)),
                (center: SIMD2(midX, midY - width / 2 - t / 2), size: SIMD2(len, t))
            ],
            renderBounds: RoomBounds(origin: SIMD2(x0, midY - width / 2 - t), size: SIMD2(len, width + t * 4)),
            axis: .horizontal
        )
    }

    private func verticalCorridorGeometry(
        y0: Float, y1: Float, midX: Float, width: Float, t: Float,
        sideWallStartY: Float, sideWallEndY: Float
    ) -> CorridorGeometry {
        let len = y1 - y0
        let sideWallHeight = sideWallEndY - sideWallStartY
        let sideWallMidY = (sideWallStartY + sideWallEndY) / 2
        let bounds = RoomBounds(origin: SIMD2(midX - width / 2, y0), size: SIMD2(width, len))
        return CorridorGeometry(
            bounds: bounds,
            walls: [
                (center: SIMD2(midX + width / 2 + t / 2, sideWallMidY), size: SIMD2(t, sideWallHeight)),
                (center: SIMD2(midX - width / 2 - t / 2, sideWallMidY), size: SIMD2(t, sideWallHeight))
            ],
            renderBounds: RoomBounds(origin: SIMD2(midX - width / 2 - t, y0), size: SIMD2(width + t * 2, len)),
            axis: .vertical
        )
    }

    private func buildCorridor(edge: DungeonEdge, from fromSpec: RoomSpecification, to toSpec: RoomSpecification, world: World) {
        guard var currentRNG = rng,
              let geometry = corridorGeometry(for: edge, from: fromSpec, to: toSpec)
        else { return }

        makeCorridorEntity(position: geometry.bounds.center, size: geometry.bounds.size, isWall: false, roomID: fromSpec.id, world: world)

        let structuralBounds: [(center: SIMD2<Float>, size: SIMD2<Float>)] = geometry.walls.map { wall in
            makeCorridorEntity(position: wall.center, size: wall.size, isWall: true, roomID: fromSpec.id, world: world)
            return wall
        }

        tileMapRenderer?.renderCorridor(
            roomID: fromSpec.id,
            bounds: geometry.renderBounds,
            axis: geometry.axis,
            theme: theme,
            using: &currentRNG
        )

        var populateContext = PopulateContext(
            world: world,
            bounds: geometry.bounds,
            scale: WorldConstants.standardEntityScale,
            roomID: fromSpec.id,
            generator: currentRNG,
            structuralBounds: structuralBounds
        )
        edge.corridor.populator.populate(context: &populateContext)
        self.rng = populateContext.generator
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
