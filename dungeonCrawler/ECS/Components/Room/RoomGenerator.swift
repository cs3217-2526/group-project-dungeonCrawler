//
//  RoomGenerator.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/3/26.
//

import Foundation
import simd
 
public final class RoomGenerator {
    
    // MARK: - Configuration
    
    public struct GenerationConfig {
        /// Minimum clear space from walls
        public var wallMargin: Float = 48
        
        /// Minimum clear radius around room center
        public var centerClearRadius: Float = 100
        
        /// Probability of spawning obstacles (0.0 - 1.0)
        public var obstacleDensity: Float = 0.15
        
        /// Wall thickness
        public var wallThickness: Float = 16
        
        public init() {}
    }
    
    private let config: GenerationConfig
    
    public init(config: GenerationConfig = GenerationConfig()) {
        self.config = config
    }
    
    // MARK: - Main Generation
    
    /// Generates the interior of a room, creating walls, floors, and obstacles
    public func generateRoomInterior(
        room: Entity,
        world: World
    ) {
        guard let roomComponent = world.getComponent(type: RoomComponent.self, for: room) else {
            return
        }
        
        let bounds = roomComponent.bounds
        
        // 1. Generate perimeter walls
        createPerimeterWalls(bounds: bounds, world: world)
        
        // 2. Generate floor tiles (optional, for visual representation)
        createFloorTiles(bounds: bounds, world: world)
        
        // TODO: add obstacles and doors
        // 3. Generate interior obstacles while preserving center navigability
//        createObstacles(bounds: bounds, world: world)
        
        // 4. Create doorway openings in walls
//        for doorway in roomComponent.doorways {
//            createDoorwayOpening(doorway: doorway, bounds: bounds, world: world)
//        }
    }
    
    // MARK: - Wall Generation
    
    private func createPerimeterWalls(bounds: RoomBounds, world: World) {
        let thickness = config.wallThickness
        print("wall thickness specified: \(thickness)")
        
        // Bottom wall
        createWallSegment(
            position: SIMD2<Float>(bounds.center.x, bounds.origin.y + thickness / 2),
            size: SIMD2<Float>(bounds.size.x - 2 * thickness, thickness),
            world: world
        )
        
        // Top wall
        createWallSegment(
            position: SIMD2<Float>(bounds.center.x, bounds.max.y - thickness / 2),
            size: SIMD2<Float>(bounds.size.x - 2 * thickness, thickness),
            world: world
        )
        
        // Left wall
        createWallSegment(
            position: SIMD2<Float>(bounds.origin.x + thickness / 2, bounds.center.y),
            size: SIMD2<Float>(thickness, bounds.size.y),
            world: world
        )
        
        // Right wall
        createWallSegment(
            position: SIMD2<Float>(bounds.max.x - thickness / 2, bounds.center.y),
            size: SIMD2<Float>(thickness, bounds.size.y),
            world: world
        )
    }
    
    private func createWallSegment(
        position: SIMD2<Float>,
        size: SIMD2<Float>,
        world: World
    ) {
        let wall = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: wall)
        world.addComponent(component: CollisionBoxComponent(size: size), to: wall)
        world.addComponent(component: SpriteComponent.wall(size: size), to: wall)
        world.addComponent(component: WallTag(), to: wall)
        print("wall of size \(size) at \(position) created")
    }
    
    // MARK: - Floor Generation
    
    private func createFloorTiles(bounds: RoomBounds, world: World) {
        let floor = world.createEntity()
        world.addComponent(component: TransformComponent(position: bounds.center), to: floor)
        world.addComponent(component: SpriteComponent.floor(size: bounds.size), to: floor)
        world.addComponent(component: FloorTag(), to: floor)
    }
    
    // MARK: - Obstacle Generation
    
    private func createObstacles(bounds: RoomBounds, world: World) {
        let margin = config.wallMargin
        let centerRadius = config.centerClearRadius
        
        // Calculate safe spawn area (excluding margins)
        let safeArea = RoomBounds(
            origin: bounds.origin + SIMD2<Float>(margin, margin),
            size: bounds.size - SIMD2<Float>(margin * 2, margin * 2)
        )
        
        // Determine number of obstacles based on room size
        let area = safeArea.size.x * safeArea.size.y
        let maxObstacles = Int(area / 5000 * config.obstacleDensity) // ~1 per 5000 sq units
        
        var attempts = 0
        var obstaclesPlaced = 0
        
        while obstaclesPlaced < maxObstacles && attempts < maxObstacles * 10 {
            attempts += 1
            
            let position = safeArea.randomPosition()
            
            // Skip if too close to center (keep center navigable)
            if distance(position, bounds.center) < centerRadius {
                continue
            }
            
            // Create obstacle
            createObstacle(at: position, world: world)
            obstaclesPlaced += 1
        }
    }
    
    // TODO: Implement Obstacle in the map
    private func createObstacle(at position: SIMD2<Float>, world: World) {
        let obstacle = world.createEntity()
        
        // Random obstacle size
        let size = SIMD2<Float>(
            Float.random(in: 24...48),
            Float.random(in: 24...48)
        )
        
        world.addComponent(component: TransformComponent(position: position), to: obstacle)
        world.addComponent(component: CollisionBoxComponent(size: size), to: obstacle)
        world.addComponent(component: SpriteComponent(textureName: "rock"), to: obstacle)
        world.addComponent(component: ObstacleTag(), to: obstacle)
    }
    
    // MARK: - Doorway Openings
    // TODO: Implement Door in the map
    
    private func createDoorwayOpening(
        doorway: Doorway,
        bounds: RoomBounds,
        world: World
    ) {
        // Create a door entity (can be locked/unlocked)
        let door = world.createEntity()
        world.addComponent(component: TransformComponent(position: doorway.position), to: door)
        world.addComponent(component: DoorTag(direction: doorway.direction), to: door)
        
        if doorway.isLocked {
            world.addComponent(component: LockedDoorTag(), to: door)
        }
        
        // Optional: add collision when locked, remove when unlocked
        if doorway.isLocked {
            world.addComponent(
                component: CollisionBoxComponent(size: SIMD2<Float>(doorway.width, 16)),
                to: door
            )
        }
        
        world.addComponent(component: SpriteComponent(textureName: "door"), to: door)
    }
}
 
// MARK: - Grid-Based Generation Extension (Not in use for now)
 
extension RoomGenerator {
    
    /// Generates a room using grid-based cellular automata or simple rules
    public func generateGridBasedRoom(room: Entity, world: World) {
        guard var roomComponent = world.getComponent(type: RoomComponent.self, for: room),
              var grid = roomComponent.gridLayout else {
            return
        }
        
        let bounds = roomComponent.bounds
        let gridSize = grid.gridSize
        
        // 1. Initialize: all floor
        for y in 0..<gridSize.y {
            for x in 0..<gridSize.x {
                grid.tiles[y][x] = .floor
            }
        }
        
        // 2. Add perimeter walls
        for x in 0..<gridSize.x {
            grid.tiles[0][x] = .wall
            grid.tiles[gridSize.y - 1][x] = .wall
        }
        for y in 0..<gridSize.y {
            grid.tiles[y][0] = .wall
            grid.tiles[y][gridSize.x - 1] = .wall
        }
        
        // 3. Add random obstacles (avoiding center)
        let centerX = gridSize.x / 2
        let centerY = gridSize.y / 2
        let centerRadius = min(gridSize.x, gridSize.y) / 4
        
        for y in 2..<(gridSize.y - 2) {
            for x in 2..<(gridSize.x - 2) {
                let dx = x - centerX
                let dy = y - centerY
                let distFromCenter = sqrt(Float(dx * dx + dy * dy))
                
                if distFromCenter > Float(centerRadius) && Float.random(in: 0...1) < config.obstacleDensity {
                    grid.tiles[y][x] = .obstacle
                }
            }
        }
        
        // 4. Instantiate grid tiles as entities
        for y in 0..<gridSize.y {
            for x in 0..<gridSize.x {
                let tileType = grid.tiles[y][x]
                guard tileType != .floor else { continue } // Don't spawn floor entities
                
                let worldPos = grid.worldPosition(gridX: x, gridY: y, roomOrigin: bounds.origin)
                createTileEntity(type: tileType, at: worldPos, cellSize: grid.cellSize, world: world)
            }
        }
        
        // Update room component with generated grid
        roomComponent.gridLayout = grid
        world.modifyComponent(type: RoomComponent.self, for: room) { component in
            component.gridLayout = grid
        }
    }
    
    private func createTileEntity(
        type: GridLayout.TileType,
        at position: SIMD2<Float>,
        cellSize: Float,
        world: World
    ) {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: entity)
        
        let tileSize = SIMD2<Float>(cellSize, cellSize)
        
        switch type {
        case .wall:
            world.addComponent(component: CollisionBoxComponent(size: tileSize), to: entity)
            world.addComponent(component: SpriteComponent(textureName: "wall_tile"), to: entity)
            world.addComponent(component: WallTag(), to: entity)
            
        case .obstacle:
            world.addComponent(component: CollisionBoxComponent(size: tileSize), to: entity)
            world.addComponent(component: SpriteComponent(textureName: "obstacle_tile"), to: entity)
            world.addComponent(component: ObstacleTag(), to: entity)
            
        case .pit:
            world.addComponent(component: SpriteComponent(textureName: "pit_tile"), to: entity)
            // Pits might have special collision or trigger behavior
            
        case .floor:
            break // Floor is background, no entity needed
        }
    }
}
