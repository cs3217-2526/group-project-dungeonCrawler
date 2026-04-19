import XCTest
import simd
@testable import dungeonCrawler

// MARK: - Mock

final class MockTileMapRenderer: TileMapRenderer {
    var renderRoomCalls:     Int = 0
    var renderCorridorCalls: Int = 0
    var renderBarrierCalls:  Int = 0
    var tearDownBarrierCalls: Int = 0
    var tearDownAllCalls:    Int = 0

    func renderRoom(roomID: UUID, bounds: RoomBounds, doorways: [Doorway],
                    theme: TileTheme, using generator: inout SeededGenerator) {
        renderRoomCalls += 1
    }
    func renderCorridor(roomID: UUID, bounds: RoomBounds, axis: CorridorAxis,
                        theme: TileTheme, using generator: inout SeededGenerator) {
        renderCorridorCalls += 1
    }
    func renderBarrier(roomID: UUID, bounds: RoomBounds, side: BarrierSide,
                       theme: TileTheme, using generator: inout SeededGenerator) {
        renderBarrierCalls += 1
    }
    func tearDownBarriers(roomID: UUID) { tearDownBarrierCalls += 1 }
    func tearDownAll()                  { tearDownAllCalls += 1 }
}

// MARK: - Tests

@MainActor
final class RoomLockdownManagerTests: XCTestCase {

    var world:      World!
    var manager:    RoomLockdownManager!
    var roomID:     UUID!
    var roomEntity: Entity!
    var builtRooms: [UUID: Entity]!

    // MARK: - Component variants

    var combatEncounterTag:  CombatEncounterTag!
    var roomInCombatTag:     RoomInCombatTag!

    // MARK: - Pre-built graphs

    var graphWithOneDoorway:  DungeonGraph!   // roomID has one east-facing doorway
    var graphWithTwoDoorways: DungeonGraph!   // roomID has east and north doorways

    // MARK: - Cross-room isolation fixtures

    var otherRoomID:     UUID!
    var otherBarrier:    Entity!
    var otherBarrierTag: BarrierTag!
    var otherMember:     RoomMemberComponent!

    // MARK: - Renderer / RNG fixtures

    var mockRenderer: MockTileMapRenderer!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        world       = World()
        manager     = RoomLockdownManager()
        roomID      = UUID()
        roomEntity  = world.createEntity()
        builtRooms  = [roomID: roomEntity]

        combatEncounterTag = CombatEncounterTag()
        roomInCombatTag    = RoomInCombatTag()
        mockRenderer       = MockTileMapRenderer()

        // Graph: roomID → one east neighbor
        let oneDoorSpec = RoomSpecification(
            id: roomID,
            bounds: RoomBounds(origin: .zero, size: SIMD2(100, 80)),
            isStartRoom: true,
            populator: EmptyRoomPopulator()
        )
        graphWithOneDoorway = DungeonGraph(startingRoomSpecification: oneDoorSpec)
        let eastNeighborID   = UUID()
        let eastNeighborSpec = RoomSpecification(
            id: eastNeighborID,
            bounds: RoomBounds(origin: SIMD2(200, 0), size: SIMD2(100, 80)),
            isStartRoom: false,
            populator: EmptyRoomPopulator()
        )
        graphWithOneDoorway.addRoom(eastNeighborSpec)
        graphWithOneDoorway.addConnection(from: roomID, to: eastNeighborID,
                                          exitDirection: .east, entryDirection: .west)

        // Graph: roomID → east + north neighbors
        let twoDoorSpec = RoomSpecification(
            id: roomID,
            bounds: RoomBounds(origin: .zero, size: SIMD2(100, 80)),
            isStartRoom: true,
            populator: EmptyRoomPopulator()
        )
        graphWithTwoDoorways = DungeonGraph(startingRoomSpecification: twoDoorSpec)
        for (dir, entry, offset) in [(Direction.east,  Direction.west,  SIMD2<Float>(200, 0)),
                                     (Direction.north, Direction.south, SIMD2<Float>(0, 180))] {
            let nID  = UUID()
            let spec = RoomSpecification(id: nID,
                                          bounds: RoomBounds(origin: offset, size: SIMD2(100, 80)),
                                          isStartRoom: false,
                                          populator: EmptyRoomPopulator())
            graphWithTwoDoorways.addRoom(spec)
            graphWithTwoDoorways.addConnection(from: roomID, to: nID,
                                               exitDirection: dir, entryDirection: entry)
        }

        // Cross-room isolation: barrier belonging to a different room
        otherRoomID     = UUID()
        otherBarrierTag = BarrierTag()
        otherMember     = RoomMemberComponent(roomID: otherRoomID)
        otherBarrier    = world.createEntity()
        world.addComponent(component: otherBarrierTag, to: otherBarrier)
        world.addComponent(component: otherMember,     to: otherBarrier)
    }

    override func tearDown() {
        world                = nil
        manager              = nil
        roomID               = nil
        roomEntity           = nil
        builtRooms           = nil
        combatEncounterTag   = nil
        roomInCombatTag      = nil
        mockRenderer         = nil
        graphWithOneDoorway  = nil
        graphWithTwoDoorways = nil
        otherRoomID          = nil
        otherBarrier         = nil
        otherBarrierTag      = nil
        otherMember          = nil
        super.tearDown()
    }

    // MARK: - requiresLockdown

    func testRequiresLockdownTrueWhenTagPresent() {
        world.addComponent(component: combatEncounterTag, to: roomEntity)
        XCTAssertTrue(manager.requiresLockdown(roomID, in: world, builtRoomEntities: builtRooms))
    }

    func testRequiresLockdownFalseWhenTagAbsent() {
        XCTAssertFalse(manager.requiresLockdown(roomID, in: world, builtRoomEntities: builtRooms))
    }

    func testRequiresLockdownFalseForUnknownRoomID() {
        XCTAssertFalse(manager.requiresLockdown(UUID(), in: world, builtRoomEntities: builtRooms))
    }

    func testLockRoomSpawnsOneBarrierPerDoorway() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let ownBarriers = world.entities(with: BarrierTag.self)
            .filter { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }
        XCTAssertEqual(ownBarriers.count, 1)
    }

    func testLockRoomSpawnsBarrierForEachDoorway() {
        manager.lockRoom(roomID, world: world, graph: graphWithTwoDoorways,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let ownBarriers = world.entities(with: BarrierTag.self)
            .filter { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }
        XCTAssertEqual(ownBarriers.count, 2)
    }

    // MARK: - lockRoom: barrier components

    func testBarrierHasBarrierTag() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let ownBarriers = world.entities(with: BarrierTag.self)
            .filter { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }
        XCTAssertFalse(ownBarriers.isEmpty)
    }

    func testBarrierHasWallTag() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let barrier = world.entities(with: BarrierTag.self)
            .first { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }!
        XCTAssertNotNil(world.getComponent(type: WallTag.self, for: barrier))
    }

    func testBarrierHasCollisionBoxComponent() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let barrier = world.entities(with: BarrierTag.self)
            .first { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }!
        XCTAssertNotNil(world.getComponent(type: CollisionBoxComponent.self, for: barrier))
    }

    func testBarrierHasTransformComponent() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let barrier = world.entities(with: BarrierTag.self)
            .first { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }!
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: barrier))
    }

    func testBarrierRoomMemberComponentMatchesRoomID() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: nil, rng: nil)

        let barrier = world.entities(with: BarrierTag.self)
            .first { world.getComponent(type: RoomMemberComponent.self, for: $0)?.roomID == roomID }!
        let member  = world.getComponent(type: RoomMemberComponent.self, for: barrier)
        XCTAssertEqual(member?.roomID, roomID)
    }

    // MARK: - lockRoom: tile renderer called

    func testLockRoomCallsRenderBarrierWhenRendererAndRNGProvided() {
        let rng = SeededGenerator(seed: 1)
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: mockRenderer, rng: rng)

        XCTAssertEqual(mockRenderer.renderBarrierCalls, 1)
    }

    func testLockRoomDoesNotCallRenderBarrierWhenRNGIsNil() {
        manager.lockRoom(roomID, world: world, graph: graphWithOneDoorway,
                         theme: .chilling, tileMapRenderer: mockRenderer, rng: nil)

        XCTAssertEqual(mockRenderer.renderBarrierCalls, 0)
    }

    // MARK: - unlockRoom: tag removal

    func testUnlockRoomRemovesCombatEncounterTag() {
        world.addComponent(component: combatEncounterTag, to: roomEntity)
        manager.unlockRoom(roomID, world: world,
                           builtRoomEntities: builtRooms, tileMapRenderer: nil)

        XCTAssertNil(world.getComponent(type: CombatEncounterTag.self, for: roomEntity))
    }

    func testUnlockRoomRemovesRoomInCombatTag() {
        world.addComponent(component: roomInCombatTag, to: roomEntity)
        manager.unlockRoom(roomID, world: world,
                           builtRoomEntities: builtRooms, tileMapRenderer: nil)

        XCTAssertNil(world.getComponent(type: RoomInCombatTag.self, for: roomEntity))
    }

    // MARK: - unlockRoom: barrier destruction

    func testUnlockRoomDoesNotDestroyBarriersFromOtherRooms() {
        manager.unlockRoom(roomID, world: world,
                           builtRoomEntities: builtRooms, tileMapRenderer: nil)

        XCTAssertTrue(world.isAlive(entity: otherBarrier),
                      "Barrier from another room should not be destroyed")
    }

    // MARK: - unlockRoom: tile renderer called

    func testUnlockRoomCallsTearDownBarriersOnRenderer() {
        manager.unlockRoom(roomID, world: world,
                           builtRoomEntities: builtRooms, tileMapRenderer: mockRenderer)

        XCTAssertEqual(mockRenderer.tearDownBarrierCalls, 1)
    }

    func testUnlockForUnknownRoomIDDoesNothing() {
        let unknownID = UUID()
        let countBefore = world.entities(with: BarrierTag.self).count

        manager.unlockRoom(unknownID, world: world,
                           builtRoomEntities: builtRooms, tileMapRenderer: nil)

        XCTAssertEqual(world.entities(with: BarrierTag.self).count, countBefore)
    }
}
