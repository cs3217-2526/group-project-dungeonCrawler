//
//  EntityFactoryTests.swift
//  dungeonCrawlerTests
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class EntityFactoryTests: XCTestCase {

    var world: World!

    override func setUp() {
        super.setUp()
        world = World()
    }

    override func tearDown() {
        world = nil
        super.tearDown()
    }

    func testMakePlayerEntityIsAlive() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        // Entity is alive if we can query a component from it
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
    }

    func testMakePlayerTransform() {
        let position = SIMD2<Float>(100, 200)
        let entity = EntityFactory.makePlayer(in: world, at: position)
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.position.x, 100, accuracy: 0.001)
        XCTAssertEqual(transform!.position.y, 200, accuracy: 0.001)
    }

    func testMakePlayerVelocity() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
        XCTAssertNotNil(velocity)
        XCTAssertEqual(velocity!.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity!.linear.y, 0, accuracy: 0.001)
    }

    func testMakePlayerInput() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: entity))
    }

    func testMakePlayerSprite() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
        XCTAssertNotNil(sprite)
        XCTAssertEqual(sprite!.textureName, "knight")
    }

    func testMakePlayerCustomTexture() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0), textureName: "warrior")
        let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
        XCTAssertNotNil(sprite)
        XCTAssertEqual(sprite!.textureName, "warrior")
    }

    func testMakePlayerTag() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        XCTAssertNotNil(world.getComponent(type: PlayerTagComponent.self, for: entity))
    }

    func testMakePlayerHealth() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let health = world.getComponent(type: HealthComponent.self, for: entity)
        XCTAssertNotNil(health)
        XCTAssertEqual(health!.value.base, 100, accuracy: 0.001)
        XCTAssertEqual(health!.value.current, 100, accuracy: 0.001)
    }

    func testMakePlayerMoveSpeed() {
        let entity = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let speed = world.getComponent(type: MoveSpeedComponent.self, for: entity)
        XCTAssertNotNil(speed)
        XCTAssertEqual(speed!.value.base, 90, accuracy: 0.001)
        XCTAssertEqual(speed!.value.current, 90, accuracy: 0.001)
    }

    func testMakePlayerReturnsDistinctEntities() {
        let entity1 = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(0, 0))
        let entity2 = EntityFactory.makePlayer(in: world, at: SIMD2<Float>(10, 10))
        XCTAssertNotEqual(entity1, entity2)
    // MARK: - makeEnemy: entity registration

    func testMakeEnemyIsAlive() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertTrue(world.isAlive(entity: enemy))
    }

    func testMakeEnemyReturnsUniqueEntities() {
        let enemy1 = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        let enemy2 = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertNotEqual(enemy1, enemy2)
    }

    // MARK: - makeEnemy: TransformComponent

    func testMakeEnemyPositionIsSet() {
        let position = SIMD2<Float>(100, 200)
        let enemy = EntityFactory.makeEnemy(in: world, at: position, type: .charger)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertEqual(transform?.position.x, 100)
        XCTAssertEqual(transform?.position.y, 200)
    }

    func testMakeEnemyDefaultScale() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertEqual(transform?.scale, 1)
    }

    func testMakeEnemyCustomScale() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger, scale: 2.5)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertEqual(transform?.scale, 2.5)
    }

    func testMakeEnemyRotationIsZero() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertEqual(transform?.rotation, 0)
    }

    // MARK: - makeEnemy: SpriteComponent

    func testMakeEnemyHasSpriteComponent() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: enemy))
    }

    func testMakeEnemyTextureMatchesType() {
        for type in [EnemyType.charger, .mummy, .ranger, .tower] {
            let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: type)
            let sprite = world.getComponent(type: SpriteComponent.self, for: enemy)
            XCTAssertEqual(sprite?.textureName, type.textureName, "Texture mismatch for \(type)")
        }
    }

    // MARK: - makeEnemy: EnemyTagComponent

    func testMakeEnemyHasEnemyTag() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertNotNil(world.getComponent(type: EnemyTagComponent.self, for: enemy))
    }

    func testMakeEnemyTagMatchesType() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .mummy)
        let tag = world.getComponent(type: EnemyTagComponent.self, for: enemy)
        XCTAssertEqual(tag?.enemyType, .mummy)
    }

    // MARK: - makeEnemy: no player components

    func testMakeEnemyHasNoInputComponent() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertNil(world.getComponent(type: InputComponent.self, for: enemy))
    }

    // For now the enemy is stationary
    // TODO: REMOVE AFTER ENEMY HAS BEEN GRANTED FUNCTIONALITY TO MOVE
    func testMakeEnemyHasNoVelocityComponent() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertNil(world.getComponent(type: VelocityComponent.self, for: enemy))
    }

    func testMakeEnemyHasNoPlayerTag() {
        let enemy = EntityFactory.makeEnemy(in: world, at: .zero, type: .charger)
        XCTAssertNil(world.getComponent(type: PlayerTagComponent.self, for: enemy))
    }

    // MARK: - makeEnemy: world queries

    func testEnemiesQueryableByTag() {
        EntityFactory.makeEnemy(in: world, at: SIMD2(0, 0),   type: .charger)
        EntityFactory.makeEnemy(in: world, at: SIMD2(100, 0), type: .mummy)
        let enemies = world.entities(with: EnemyTagComponent.self)
        XCTAssertEqual(enemies.count, 2)
    }

    func testPlayerAndEnemiesAreIsolated() {
        EntityFactory.makePlayer(in: world, at: .zero)
        EntityFactory.makeEnemy(in: world, at: SIMD2(100, 0), type: .charger)

        let players = world.entities(with: PlayerTagComponent.self)
        let enemies = world.entities(with: EnemyTagComponent.self)

        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(enemies.count, 1)
        XCTAssertNotEqual(players.first, enemies.first)
    }
}
