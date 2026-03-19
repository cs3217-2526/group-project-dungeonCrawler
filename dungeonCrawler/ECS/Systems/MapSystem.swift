//
//  MapSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 18/3/26.
//

import Foundation
import simd

public final class MapSystem: System {
    public let priority: Int = 5 // Early in the update cycle
    
    private let roomGenerator = RoomGenerator()
    private var currentRoomEntity: Entity?
    
    // MARK: - Update
    
    public func update(deltaTime: Double, world: World) {}
    
    // MARK: - Room Generation
    
    /// Generates a new room and populates it with obstacles and enemies
    @discardableResult
    public func generateAndActivateRoom(
        bounds: RoomBounds,
        world: World,
        doorways: [Doorway] = [],
        size: CGSize
    ) -> Entity {
        // 1. Create room entity
        let room = EntityFactory.makeRoom(in: world, bounds: bounds, doorways: doorways)
        
        // 2. Generate interior (walls, obstacles)
        roomGenerator.generateRoomInterior(room: room, world: world)
        
        // 3. Add spawn points
        addSpawnPoints(to: room, world: world)
        
        // 4. Spawn initial enemies
        let shortSide = Float(min(size.width, size.height))
        let scale = shortSide * 0.04 / 48.0
        spawnEnemies(in: room, world: world, scale: scale)
        
        // 5. Mark as locked (player must clear to proceed)
        world.addComponent(component: RoomLockedTag(), to: room)
        world.addComponent(component: RoomInCombatTag(), to: room)
        
        return room
    }
    
    // MARK: - Spawn Point Management
    
    private func addSpawnPoints(to room: Entity, world: World) {
        guard let roomComponent = world.getComponent(type: RoomComponent.self, for: room) else {
            return
        }
        
        let bounds = roomComponent.bounds
        var spawnPoints: [SpawnPoint] = []
        
        // Player entry point (usually at a doorway or room center)
        if let firstDoorway = roomComponent.doorways.first {
            // Offset slightly into the room from the doorway
            let offset = firstDoorway.direction.vector * 50
            spawnPoints.append(SpawnPoint(
                position: firstDoorway.position + offset,
                type: .playerEntry
            ))
        } else {
            // No doorway, spawn at center
            print("there is no doorway, player spawned in the middle")
            spawnPoints.append(SpawnPoint(
                position: bounds.center,
                type: .playerEntry
            ))
        }
        
        // Random enemy spawn points, for now spawning 3
        for _ in 0..<3 {
            spawnPoints.append(SpawnPoint(
                position: bounds.randomPosition(margin: 80),
                type: .enemy
            ))
        }
        
        // Update room component
        world.modifyComponent(type: RoomComponent.self, for: room) { component in
            component.spawnPoints = spawnPoints
        }
    }
    
    // MARK: - Entity Spawning within Room Coordinates
    
    private func spawnEnemies(in room: Entity, world: World, scale: Float) {
        guard let roomComponent = world.getComponent(type: RoomComponent.self, for: room) else {
            return
        }
        
        // Get all enemy spawn points
        let enemySpawns = roomComponent.spawnPoints.filter { $0.type == .enemy }
        
        for spawnPoint in enemySpawns {
            // Ensure spawn point is within room bounds
            guard roomComponent.bounds.contains(spawnPoint.position) else {
                continue
            }
            
            // Spawn enemy at this position
            let enemyType = [EnemyType.charger, EnemyType.mummy, EnemyType.ranger].randomElement()!
            EntityFactory.makeEnemy(
                in: world,
                at: spawnPoint.position,
                type: enemyType,
                baseScale: scale * enemyType.scale
            )
        }
    }
    
    /// Spawns the player at the designated entry point
    public func spawnPlayerInRoom(room: Entity, world: World, size: CGSize) {
        guard let roomComponent = world.getComponent(type: RoomComponent.self, for: room) else {
            return
        }
        
        let shortSide = Float(min(size.width, size.height))
        let scale = shortSide * 0.04 / 48.0
                
        // Find player entry spawn point
        if let entryPoint = roomComponent.spawnPoints.first(where: { $0.type == .playerEntry }) {
            // Move existing player or create new one
            if let player = findPlayer(in: world) {
                world.modifyComponent(type: TransformComponent.self, for: player) { transform in
                    transform.position = entryPoint.position
                }
            } else {
                EntityFactory.makePlayer(in: world, at: entryPoint.position, scale: scale)
            }
        }
    }
    
    
    
    // MARK: - Helpers
    
    private func findPlayer(in world: World) -> Entity? {
        world.entities(with: PlayerTagComponent.self).first
    }
}
