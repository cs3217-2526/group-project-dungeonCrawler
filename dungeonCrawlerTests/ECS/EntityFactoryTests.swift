//
//  EntityFactoryTests.swift
//  dungeonCrawlerTests
//
//  Created by Wen Kang Yap on 16/3/26.
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

    // MARK: - makePlayer

    func testMakePlayerEntityIsAlive() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        // Entity is alive if we can query a component from it
        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity))
    }

    func testMakePlayerTransform() {
        let position = SIMD2<Float>(100, 200)
        let entity = PlayerEntityFactory(at: position).make(in: world)
        let transform = world.getComponent(type: TransformComponent.self, for: entity)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.position.x, 100, accuracy: 0.001)
        XCTAssertEqual(transform!.position.y, 200, accuracy: 0.001)
    }

    func testMakePlayerVelocity() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        let velocity = world.getComponent(type: VelocityComponent.self, for: entity)
        XCTAssertNotNil(velocity)
        XCTAssertEqual(velocity!.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity!.linear.y, 0, accuracy: 0.001)
    }

    func testMakePlayerInput() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        XCTAssertNotNil(world.getComponent(type: InputComponent.self, for: entity))
    }

    func testMakePlayerSprite() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
        XCTAssertNotNil(sprite)
        guard case .texture(let name) = sprite!.content else {
            XCTFail("Expected .texture content")
            return
        }
        XCTAssertEqual(name, "knight")
    }

    func testMakePlayerCustomTexture() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0), textureName: "warrior").make(in: world)
        let sprite = world.getComponent(type: SpriteComponent.self, for: entity)
        XCTAssertNotNil(sprite)
        guard case .texture(let name) = sprite!.content else {
            XCTFail("Expected .texture content")
            return
        }
        XCTAssertEqual(name, "warrior")
    }

    func testMakePlayerTag() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        XCTAssertNotNil(world.getComponent(type: PlayerTagComponent.self, for: entity))
    }

    func testMakePlayerHealth() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        let health = world.getComponent(type: HealthComponent.self, for: entity)
        XCTAssertNotNil(health)
        XCTAssertEqual(health!.value.base, 100, accuracy: 0.001)
        XCTAssertEqual(health!.value.current, 100, accuracy: 0.001)
    }

    func testMakePlayerMoveSpeed() {
        let entity = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        let speed = world.getComponent(type: MoveSpeedComponent.self, for: entity)
        XCTAssertNotNil(speed)
        XCTAssertEqual(speed!.value.base, 90, accuracy: 0.001)
        XCTAssertEqual(speed!.value.current, 90, accuracy: 0.001)
    }

    // MARK: - makePlayer: CollisionBoxComponent

    func testMakePlayerHasCollisionBox() {
        let entity = PlayerEntityFactory(at: .zero).make(in: world)
        XCTAssertNotNil(world.getComponent(type: CollisionBoxComponent.self, for: entity))
    }

    func testMakePlayerCollisionBoxSizeMatchesScale() {
        let scale: Float = 2.0
        let entity = PlayerEntityFactory(at: .zero, scale: scale).make(in: world)
        let box = world.getComponent(type: CollisionBoxComponent.self, for: entity)
        XCTAssertNotNil(box)
        XCTAssertEqual(box!.width, WorldConstants.playerSize * scale, accuracy: 0.001)
        XCTAssertEqual(box!.height, WorldConstants.playerSize * scale, accuracy: 0.001)
    }

    func testMakePlayerReturnsDistinctEntities() {
        let entity1 = PlayerEntityFactory(at: SIMD2<Float>(0, 0)).make(in: world)
        let entity2 = PlayerEntityFactory(at: SIMD2<Float>(10, 10)).make(in: world)
        XCTAssertNotEqual(entity1, entity2)
    }

    // MARK: - makeEnemy: entity registration

    func testMakeEnemyIsAlive() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertTrue(world.isAlive(entity: enemy))
    }

    func testMakeEnemyReturnsUniqueEntities() {
        let enemy1 = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        let enemy2 = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNotEqual(enemy1, enemy2)
    }

    // MARK: - makeEnemy: TransformComponent

    func testMakeEnemyPositionIsSet() {
        let position = SIMD2<Float>(100, 200)
        let enemy = EnemyEntityFactory(at: position, type: .charger).make(in: world)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.position.x, 100, accuracy: 0.001)
        XCTAssertEqual(transform!.position.y, 200, accuracy: 0.001)
    }

    func testMakeEnemyRotationIsZero() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.rotation, 0, accuracy: 0.001)
    }

    func testMakeEnemyDefaultBaseScaleUsesTypeScale() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.scale, EnemyType.charger.scale, accuracy: 0.001)
    }

    func testMakeEnemyScaleIsBaseScaleTimesTypeScale() {
        let baseScale: Float = 2.0
        let enemy = EnemyEntityFactory(at: .zero, type: .tower, baseScale: baseScale).make(in: world)
        let transform = world.getComponent(type: TransformComponent.self, for: enemy)
        XCTAssertNotNil(transform)
        XCTAssertEqual(transform!.scale, baseScale * EnemyType.tower.scale, accuracy: 0.001)
    }

    // MARK: - makeEnemy: SpriteComponent

    func testMakeEnemyHasSpriteComponent() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: enemy))
    }

    func testMakeEnemyTextureMatchesType() {
        for enemyType in [EnemyType.charger, .mummy, .ranger, .tower] {
            let enemy = EnemyEntityFactory(at: .zero, type: enemyType).make(in: world)
            let sprite = world.getComponent(type: SpriteComponent.self, for: enemy)
            XCTAssertNotNil(sprite, "Missing sprite for \(enemyType)")
            guard case .texture(let name) = sprite!.content else {
                XCTFail("Expected .texture content for \(enemyType)")
                continue
            }
            XCTAssertEqual(name, enemyType.textureName, "Texture mismatch for \(enemyType)")
        }
    }

    // MARK: - makeEnemy: EnemyTagComponent

    func testMakeEnemyHasEnemyTag() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNotNil(world.getComponent(type: EnemyTagComponent.self, for: enemy))
    }

    func testMakeEnemyTagStoresCorrectRawData() {
        let enemy = EnemyEntityFactory(at: .zero, type: .mummy).make(in: world)
        let tag = world.getComponent(type: EnemyTagComponent.self, for: enemy)
        XCTAssertNotNil(tag)
        XCTAssertEqual(tag!.textureName, "Mummy")
        XCTAssertEqual(tag!.scale, 1.0, accuracy: 0.001)
    }

    // MARK: - makeEnemy: VelocityComponent and EnemyStateComponent

    func testMakeEnemyHasVelocityComponent() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNotNil(world.getComponent(type: VelocityComponent.self, for: enemy))
    }

    func testMakeEnemyVelocityStartsAtZero() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        let velocity = world.getComponent(type: VelocityComponent.self, for: enemy)
        XCTAssertNotNil(velocity)
        XCTAssertEqual(velocity!.linear.x, 0, accuracy: 0.001)
        XCTAssertEqual(velocity!.linear.y, 0, accuracy: 0.001)
    }

    func testMakeEnemyHasEnemyStateComponent() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNotNil(world.getComponent(type: EnemyStateComponent.self, for: enemy))
    }

    func testMakeEnemyStartsInWanderMode() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        let state = world.getComponent(type: EnemyStateComponent.self, for: enemy)
        XCTAssertNotNil(state)
        XCTAssertTrue(state!.mode == .wander)
    }

    // MARK: - makeEnemy: CollisionBoxComponent

    func testMakeEnemyHasCollisionBox() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNotNil(world.getComponent(type: CollisionBoxComponent.self, for: enemy))
    }

    func testMakeEnemyCollisionBoxSizeMatchesScale() {
        let baseScale: Float = 2.0
        let enemy = EnemyEntityFactory(at: .zero, type: .charger, baseScale: baseScale).make(in: world)
        let box = world.getComponent(type: CollisionBoxComponent.self, for: enemy)
        let expectedSize = WorldConstants.playerSize * baseScale * EnemyType.charger.scale
        XCTAssertNotNil(box)
        XCTAssertEqual(box!.width, expectedSize, accuracy: 0.001)
        XCTAssertEqual(box!.height, expectedSize, accuracy: 0.001)
    }

    // MARK: - makeEnemy: no player components

    func testMakeEnemyHasNoInputComponent() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNil(world.getComponent(type: InputComponent.self, for: enemy))
    }

    func testMakeEnemyHasNoPlayerTag() {
        let enemy = EnemyEntityFactory(at: .zero, type: .charger).make(in: world)
        XCTAssertNil(world.getComponent(type: PlayerTagComponent.self, for: enemy))
    }

    // MARK: - makeEnemy: world queries

    func testEnemiesQueryableByTag() {
        EnemyEntityFactory(at: SIMD2(0, 0),   type: .charger).make(in: world)
        EnemyEntityFactory(at: SIMD2(100, 0), type: .mummy).make(in: world)
        let enemies = world.entities(with: EnemyTagComponent.self)
        XCTAssertEqual(enemies.count, 2)
    }

    func testPlayerAndEnemiesAreIsolated() {
        PlayerEntityFactory(at: .zero).make(in: world)
        EnemyEntityFactory(at: SIMD2(100, 0), type: .charger).make(in: world)

        let players = world.entities(with: PlayerTagComponent.self)
        let enemies = world.entities(with: EnemyTagComponent.self)

        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(enemies.count, 1)
        XCTAssertNotEqual(players.first, enemies.first)
    }

    // MARK: - EnemyType: strategy properties (Updated on Sprint 2)

    func testChargerWanderStrategyIsWanderStrategy() {
        XCTAssertTrue(EnemyType.charger.wanderStrategy is WanderStrategy)
    }

    func testMummyWanderStrategyIsWanderStrategy() {
        XCTAssertTrue(EnemyType.mummy.wanderStrategy is WanderStrategy)
    }

    func testRangerWanderStrategyIsWanderStrategy() {
        XCTAssertTrue(EnemyType.ranger.wanderStrategy is WanderStrategy)
    }

    func testTowerWanderStrategyIsStationaryStrategy() {
        XCTAssertTrue(EnemyType.tower.wanderStrategy is StationaryStrategy)
    }

    func testChargerChaseStrategyIsStraightLineChase() {
        XCTAssertTrue(EnemyType.charger.chaseStrategy is StraightLineChaseStrategy)
    }

    func testMummyChaseStrategyIsStraightLineChase() {
        XCTAssertTrue(EnemyType.mummy.chaseStrategy is StraightLineChaseStrategy)
    }

    func testRangerChaseStrategyIsShooterBasic() {
        XCTAssertTrue(EnemyType.ranger.chaseStrategy is ShooterBasicStrategy)
    }

    func testTowerChaseStrategyIsStationaryStrategy() {
        XCTAssertTrue(EnemyType.tower.chaseStrategy is StationaryStrategy)
    }

    // MARK: - makeEnemy: EnemyStateComponent strategies

    func testMakeEnemyWanderStrategyMatchesType() {
        for enemyType in [EnemyType.charger, .mummy, .ranger, .tower] {
            let enemy = EnemyEntityFactory(at: .zero, type: enemyType).make(in: world)
            let state = world.getComponent(type: EnemyStateComponent.self, for: enemy)
            XCTAssertNotNil(state, "Missing EnemyStateComponent for \(enemyType)")
            XCTAssertTrue(
                type(of: state!.wanderStrategy) == type(of: enemyType.wanderStrategy),
                "wanderStrategy type mismatch for \(enemyType)"
            )
        }
    }

    func testMakeEnemyChaseStrategyMatchesType() {
        for enemyType in [EnemyType.charger, .mummy, .ranger, .tower] {
            let enemy = EnemyEntityFactory(at: .zero, type: enemyType).make(in: world)
            let state = world.getComponent(type: EnemyStateComponent.self, for: enemy)
            XCTAssertNotNil(state, "Missing EnemyStateComponent for \(enemyType)")
            XCTAssertTrue(
                type(of: state!.chaseStrategy) == type(of: enemyType.chaseStrategy),
                "chaseStrategy type mismatch for \(enemyType)"
            )
        }
    }
}
