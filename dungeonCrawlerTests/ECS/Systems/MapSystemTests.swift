//
//  MapSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 19/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler
 
@MainActor
final class MapSystemTests: XCTestCase {
 
    // MARK: - Helpers
 
    private var world: World!
    private var mapSystem: MapSystem!
 
    /// A standard room size used across tests — large enough that
    /// spawn point margins (80pt) and wall thickness (16pt) don't conflict.
    private let standardBounds = RoomBounds(
        origin: SIMD2<Float>(-300, -200),
        size:   SIMD2<Float>(600, 400)
    )
 
    /// A CGSize that produces a predictable, non-zero enemy scale.
    private let screenSize = CGSize(width: 390, height: 844)
 
    override func setUp() {
        super.setUp()
        world     = World()
        mapSystem = MapSystem()
    }
 
    override func tearDown() {
        world     = nil
        mapSystem = nil
        super.tearDown()
    }
 
    // MARK: - generateAndActivateRoom
 
    func test_generateAndActivateRoom_returnsLivingEntity() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        XCTAssertTrue(world.isAlive(entity: room))
    }
 
    func test_generateAndActivateRoom_roomHasRoomComponent() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)
        XCTAssertNotNil(component)
    }
 
    func test_generateAndActivateRoom_roomBoundsMatchInput() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        XCTAssertEqual(component.bounds.origin.x, standardBounds.origin.x, accuracy: 0.001)
        XCTAssertEqual(component.bounds.origin.y, standardBounds.origin.y, accuracy: 0.001)
        XCTAssertEqual(component.bounds.size.x,   standardBounds.size.x,   accuracy: 0.001)
        XCTAssertEqual(component.bounds.size.y,   standardBounds.size.y,   accuracy: 0.001)
    }
 
    func test_generateAndActivateRoom_roomIsTaggedLocked() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        XCTAssertNotNil(world.getComponent(type: RoomLockedTag.self, for: room))
    }
 
    func test_generateAndActivateRoom_roomIsTaggedInCombat() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        XCTAssertNotNil(world.getComponent(type: RoomInCombatTag.self, for: room))
    }
 
    func test_generateAndActivateRoom_spawnPointsArePopulated() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        // Expect at least 1 playerEntry + up to 5 enemy spawn points
        XCTAssertFalse(component.spawnPoints.isEmpty)
    }
 
    func test_generateAndActivateRoom_hasExactlyOnePlayerEntrySpawnPoint() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        let entryPoints = component.spawnPoints.filter { $0.type == .playerEntry }
        XCTAssertEqual(entryPoints.count, 1)
    }
 
    func test_generateAndActivateRoom_playerEntryIsInsideBounds() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        let entry = component.spawnPoints.first { $0.type == .playerEntry }!
        XCTAssertTrue(standardBounds.contains(entry.position))
    }
 
    func test_generateAndActivateRoom_enemySpawnPointsAreInsideBounds() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        let enemySpawns = component.spawnPoints.filter { $0.type == .enemy }
        for spawn in enemySpawns {
            XCTAssertTrue(
                standardBounds.contains(spawn.position),
                "Enemy spawn \(spawn.position) is outside room bounds"
            )
        }
    }
 
    func test_generateAndActivateRoom_spawnsEnemiesInWorld() {
        mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let enemies = world.entities(with: EnemyTagComponent.self)
        XCTAssertFalse(enemies.isEmpty)
    }
 
    func test_generateAndActivateRoom_createsWallEntities() {
        mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let walls = world.entities(with: WallTag.self)
        // 4 perimeter walls expected
        XCTAssertEqual(walls.count, 4)
    }
 
    func test_generateAndActivateRoom_createsFloorEntity() {
        mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let floors = world.entities(with: FloorTag.self)
        XCTAssertEqual(floors.count, 1)
    }
 
    func test_generateAndActivateRoom_wallsHaveCollisionBoxes() {
        mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        let walls = world.entities(with: WallTag.self)
        for wall in walls {
            XCTAssertNotNil(
                world.getComponent(type: CollisionBoxComponent.self, for: wall),
                "Wall entity \(wall.id) is missing a CollisionBoxComponent"
            )
        }
    }
 
    func test_generateAndActivateRoom_withoutDoorway_playerEntryAtCenter() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, doorways: [], size: screenSize
        )
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        let entry = component.spawnPoints.first { $0.type == .playerEntry }!
 
        XCTAssertEqual(entry.position.x, standardBounds.center.x, accuracy: 0.001)
        XCTAssertEqual(entry.position.y, standardBounds.center.y, accuracy: 0.001)
    }
 
    // MARK: - spawnPlayerInRoom
 
    func test_spawnPlayerInRoom_createsPlayerEntity() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        mapSystem.spawnPlayerInRoom(room: room, world: world, size: screenSize)
 
        let players = world.entities(with: PlayerTagComponent.self)
        XCTAssertEqual(players.count, 1)
    }
 
    func test_spawnPlayerInRoom_playerSpawnedAtEntryPoint() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        mapSystem.spawnPlayerInRoom(room: room, world: world, size: screenSize)
 
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        let entry = component.spawnPoints.first { $0.type == .playerEntry }!
 
        let player = world.entities(with: PlayerTagComponent.self).first!
        let transform = world.getComponent(type: TransformComponent.self, for: player)!
 
        XCTAssertEqual(transform.position.x, entry.position.x, accuracy: 0.001)
        XCTAssertEqual(transform.position.y, entry.position.y, accuracy: 0.001)
    }
 
    func test_spawnPlayerInRoom_calledTwice_doesNotDuplicatePlayer() {
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        mapSystem.spawnPlayerInRoom(room: room, world: world, size: screenSize)
        mapSystem.spawnPlayerInRoom(room: room, world: world, size: screenSize)
 
        let players = world.entities(with: PlayerTagComponent.self)
        XCTAssertEqual(players.count, 1)
    }
 
    func test_spawnPlayerInRoom_movesExistingPlayer() {
        // Pre-create a player at a known position
        EntityFactory.makePlayer(in: world, at: SIMD2(999, 999), scale: 1)
 
        let room = mapSystem.generateAndActivateRoom(
            bounds: standardBounds, world: world, size: screenSize
        )
        mapSystem.spawnPlayerInRoom(room: room, world: world, size: screenSize)
 
        let component = world.getComponent(type: RoomComponent.self, for: room)!
        let entry = component.spawnPoints.first { $0.type == .playerEntry }!
 
        let player = world.entities(with: PlayerTagComponent.self).first!
        let transform = world.getComponent(type: TransformComponent.self, for: player)!
 
        // Player should have moved to the entry point, not stay at (999, 999)
        XCTAssertEqual(transform.position.x, entry.position.x, accuracy: 0.001)
        XCTAssertEqual(transform.position.y, entry.position.y, accuracy: 0.001)
    }
}
