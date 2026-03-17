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
