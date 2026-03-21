//
//  CollisionSystemTests.swift
//  dungeonCrawler
//
//  Created by Yu Letian on 16/3/26.
//

import XCTest
import simd
@testable import dungeonCrawler

final class CollisionSystemTests: XCTestCase {

    var world: World!
    var collisionSystem: CollisionSystem!
    let collisionEvents   = CollisionEventBuffer()
    let destructionQueue  = DestructionQueue()

    override func setUp() {
        super.setUp()
        world = World()
        collisionSystem = CollisionSystem(events: collisionEvents,  destructionQueue: destructionQueue)
    }
    
    // MARK: - Entity helpers
     
    /// Bare collidable — no VelocityComponent, so treated as static (wall/obstacle).
    private func makeStaticEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: WallTag(), to: entity)
        return entity
    }
 
    /// Has VelocityComponent — treated as a dynamic enemy.
    private func makeEnemyEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyTagComponent(enemyType: .charger), to: entity)
        return entity
    }
 
    /// Has VelocityComponent + PlayerTagComponent.
    private func makePlayerEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        return entity
    }

    // Creates an entity with the components required for collision testing.
    // TODO: add stats when ready
    private func makeCollidableEntity(at position: SIMD2<Float>, size: SIMD2<Float>, rotation: Float = 0) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, rotation: rotation, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        return entity
    }

    // no collision when entities do not overlap

    func testNoCollisionWhenSeparated() {
        let box = SIMD2<Float>(10, 10)
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(10, 0), scale: 1) // 10 apart, 5 each side = touching exactly
        let boxComp = CollisionBoxComponent(size: box)

        // Exactly touching (distance == sum of half-widths) is NOT a collision.
        XCTAssertFalse(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxComp,
            transformB: transformB, boxB: boxComp
        ))
    }


    func testNoCollisionWhenClearlyApart() {
        let box = SIMD2<Float>(10, 10)
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(100, 0), scale: 1)
        let boxComp = CollisionBoxComponent(size: box)

        XCTAssertFalse(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxComp,
            transformB: transformB, boxB: boxComp
        ))
    }
    
    // collision detected when entities overlap

    func testCollisionWhenOverlapping() {
        let box = SIMD2<Float>(10, 10)
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(5, 0), scale: 1) // 5 apart, boxes overlap by 5
        let boxComp = CollisionBoxComponent(size: box)

        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxComp,
            transformB: transformB, boxB: boxComp
        ))
    }
    
    func testCollisionWithDifferentBoxSize() {
        // A at (0,0) size (10,10): right edge at x=5
        // B at (10,0) size (20,20): left edge at x=0, overlap of 5
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(10, 0), scale: 1)
        let boxCompA = CollisionBoxComponent(size: SIMD2<Float>(10, 10))
        let boxCompB = CollisionBoxComponent(size: SIMD2<Float>(20, 20))

        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxCompA,
            transformB: transformB, boxB: boxCompB
        ))
    }

    func testCollisionWithRotation() {
        // A at (0,0) size (10,10): right edge at x=5
        // B at (10,0) size (20,20) rotated 45 degrees: left edge extends to x=-5, overlap of 10
        let transformA = TransformComponent(position: SIMD2<Float>(0, 0), rotation: 0, scale: 1)
        let transformB = TransformComponent(position: SIMD2<Float>(10, 0), rotation: .pi / 4, scale: 1)
        let boxCompA = CollisionBoxComponent(size: SIMD2<Float>(10, 10))
        let boxCompB = CollisionBoxComponent(size: SIMD2<Float>(20, 20))

        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformA, boxA: boxCompA,
            transformB: transformB, boxB: boxCompB
        ))
    }
    
    // MARK: dynamic vs static (wall)
     
    func test_playerHitsWall_onlyPlayerMoves() {
        let box    = SIMD2<Float>(20, 20)
        let wall   = makeStaticEntity(at: SIMD2(15, 0), size: box)
        let player = makePlayerEntity(at: SIMD2(0,  0), size: box)
 
        let wallPosBefore = world.getComponent(type: TransformComponent.self, for: wall)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let wallPosAfter   = world.getComponent(type: TransformComponent.self, for: wall)!.position
        let playerPosAfter = world.getComponent(type: TransformComponent.self, for: player)!.position
 
        XCTAssertEqual(wallPosAfter.x, wallPosBefore.x, accuracy: 0.001, "Wall must not move")
        XCTAssertEqual(wallPosAfter.y, wallPosBefore.y, accuracy: 0.001, "Wall must not move")
        XCTAssertNotEqual(playerPosAfter.x, 0, "Player should have been pushed")
    }
 
    func test_enemyHitsWall_onlyEnemyMoves() {
        let box   = SIMD2<Float>(20, 20)
        let wall  = makeStaticEntity(at: SIMD2(15, 0), size: box)
        let enemy = makeEnemyEntity( at: SIMD2(0,  0), size: box)
 
        let wallPosBefore = world.getComponent(type: TransformComponent.self, for: wall)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let wallPosAfter  = world.getComponent(type: TransformComponent.self, for: wall)!.position
        let enemyPosAfter = world.getComponent(type: TransformComponent.self, for: enemy)!.position
 
        XCTAssertEqual(wallPosAfter.x, wallPosBefore.x, accuracy: 0.001, "Wall must not move")
        XCTAssertEqual(wallPosAfter.y, wallPosBefore.y, accuracy: 0.001, "Wall must not move")
        XCTAssertNotEqual(enemyPosAfter.x, 0, "Enemy should have been pushed")
    }
 
    func test_wallVsWall_neitherMoves() {
        let box   = SIMD2<Float>(20, 20)
        let wallA = makeStaticEntity(at: SIMD2(0,  0), size: box)
        let wallB = makeStaticEntity(at: SIMD2(15, 0), size: box)
 
        let posABefore = world.getComponent(type: TransformComponent.self, for: wallA)!.position
        let posBBefore = world.getComponent(type: TransformComponent.self, for: wallB)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        XCTAssertEqual(world.getComponent(type: TransformComponent.self, for: wallA)!.position.x, posABefore.x, accuracy: 0.001)
        XCTAssertEqual(world.getComponent(type: TransformComponent.self, for: wallB)!.position.x, posBBefore.x, accuracy: 0.001)
    }
 
    // MARK: player vs enemy
 
    func test_playerVsEnemy_bothReceiveKnockback() {
        let box    = SIMD2<Float>(20, 20)
        let player = makePlayerEntity(at: SIMD2(0,  0), size: box)
        let enemy  = makeEnemyEntity( at: SIMD2(15, 0), size: box)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        XCTAssertNotNil(world.getComponent(type: KnockbackComponent.self, for: player), "Player should receive knockback")
        XCTAssertNotNil(world.getComponent(type: KnockbackComponent.self, for: enemy),  "Enemy should receive knockback")
    }
 
    func test_playerVsEnemy_knockbackDirectionsAreOpposite() {
        let box    = SIMD2<Float>(20, 20)
        let player = makePlayerEntity(at: SIMD2(0,  0), size: box)
        let enemy  = makeEnemyEntity( at: SIMD2(15, 0), size: box)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let playerKB = world.getComponent(type: KnockbackComponent.self, for: player)!
        let enemyKB  = world.getComponent(type: KnockbackComponent.self, for: enemy)!
 
        XCTAssertTrue(playerKB.velocity.x * enemyKB.velocity.x < 0,
                      "Player and enemy knockback velocities should point in opposite directions")
    }
 
    func test_playerVsEnemy_enemyDisplacedMoreThanPlayer() {
        let box    = SIMD2<Float>(20, 20)
        let player = makePlayerEntity(at: SIMD2(0,  0), size: box)
        let enemy  = makeEnemyEntity( at: SIMD2(15, 0), size: box)
 
        let playerPosBefore = world.getComponent(type: TransformComponent.self, for: player)!.position
        let enemyPosBefore  = world.getComponent(type: TransformComponent.self, for: enemy)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let playerDisp = abs(world.getComponent(type: TransformComponent.self, for: player)!.position.x - playerPosBefore.x)
        let enemyDisp  = abs(world.getComponent(type: TransformComponent.self, for: enemy)!.position.x  - enemyPosBefore.x)
 
        XCTAssertGreaterThan(enemyDisp, playerDisp,
                             "Enemy bounce factor (0.75) should displace more than player bounce factor (0.1)")
    }
 
    func test_playerVsEnemy_existingKnockbackNotOverwritten() {
        let box    = SIMD2<Float>(20, 20)
        let player = makePlayerEntity(at: SIMD2(0,  0), size: box)
        _          = makeEnemyEntity( at: SIMD2(15, 0), size: box)
 
        let existingVelocity = SIMD2<Float>(999, 0)
        world.addComponent(component: KnockbackComponent(velocity: existingVelocity, remainingTime: 1.0), to: player)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let kb = world.getComponent(type: KnockbackComponent.self, for: player)!
        XCTAssertEqual(kb.velocity.x, existingVelocity.x, accuracy: 0.001,
                       "Existing knockback should not be overwritten by a new collision")
    }
 
    // MARK: enemy vs enemy
 
    func test_enemyVsEnemy_equalDisplacement() {
        let box    = SIMD2<Float>(20, 20)
        let enemyA = makeEnemyEntity(at: SIMD2(0,  0), size: box)
        let enemyB = makeEnemyEntity(at: SIMD2(15, 0), size: box)
 
        let posABefore = world.getComponent(type: TransformComponent.self, for: enemyA)!.position
        let posBBefore = world.getComponent(type: TransformComponent.self, for: enemyB)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let dispA = abs(world.getComponent(type: TransformComponent.self, for: enemyA)!.position.x - posABefore.x)
        let dispB = abs(world.getComponent(type: TransformComponent.self, for: enemyB)!.position.x - posBBefore.x)
 
        XCTAssertEqual(dispA, dispB, accuracy: 0.001, "Both enemies should be displaced by equal amounts")
    }
 
    func test_enemyVsEnemy_noKnockbackApplied() {
        let box    = SIMD2<Float>(20, 20)
        let enemyA = makeEnemyEntity(at: SIMD2(0,  0), size: box)
        let enemyB = makeEnemyEntity(at: SIMD2(15, 0), size: box)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        XCTAssertNil(world.getComponent(type: KnockbackComponent.self, for: enemyA), "Enemy-vs-enemy should not apply knockback")
        XCTAssertNil(world.getComponent(type: KnockbackComponent.self, for: enemyB), "Enemy-vs-enemy should not apply knockback")
    }
}
