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
    var collisionEvents: CollisionEventBuffer!
    var destructionQueue: DestructionQueue!

    // Shared box size used by the majority of tests.
    let defaultBox = SIMD2<Float>(20, 20)

    // Shared transform + box components for the pure checkCollision tests.
    var transformOrigin: TransformComponent!
    var transformNear: TransformComponent!
    var transformFar: TransformComponent!
    var transformOverlapping: TransformComponent!
    var transformBRotated: TransformComponent!
    var smallBox: CollisionBoxComponent!
    var largeBox: CollisionBoxComponent!

    override func setUp() {
        super.setUp()
        collisionEvents  = CollisionEventBuffer()
        destructionQueue = DestructionQueue()
        world            = World()
        collisionSystem  = CollisionSystem(events: collisionEvents, destructionQueue: destructionQueue)

        transformOrigin     = TransformComponent(position: SIMD2<Float>(0,   0), rotation: 0,        scale: 1)
        transformNear       = TransformComponent(position: SIMD2<Float>(10,  0), rotation: 0,        scale: 1)
        transformFar        = TransformComponent(position: SIMD2<Float>(100, 0), rotation: 0,        scale: 1)
        transformOverlapping = TransformComponent(position: SIMD2<Float>(5,  0), rotation: 0,        scale: 1)
        transformBRotated   = TransformComponent(position: SIMD2<Float>(10, 0),  rotation: .pi / 4,  scale: 1)
        smallBox            = CollisionBoxComponent(size: SIMD2<Float>(10, 10))
        largeBox            = CollisionBoxComponent(size: SIMD2<Float>(20, 20))
    }

    override func tearDown() {
        world            = nil
        collisionSystem  = nil
        collisionEvents  = nil
        destructionQueue = nil
        transformOrigin      = nil
        transformNear        = nil
        transformFar         = nil
        transformOverlapping = nil
        transformBRotated    = nil
        smallBox         = nil
        largeBox         = nil
        super.tearDown()
    }
    
    // MARK: - Entity helpers

    @discardableResult
    /// Bare collidable — no VelocityComponent, so treated as static (wall/obstacle).
    private func makeStaticEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: WallTag(), to: entity)
        return entity
    }

    @discardableResult
    /// Light enemy (ranger, mass 5) — knocked back more.
    private func makeLightWeightEnemyEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyTagComponent(textureName: EnemyType.ranger.textureName, scale: EnemyType.ranger.scale), to: entity)
        world.addComponent(component: MassComponent(mass: EnemyType.ranger.mass), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        return entity
    }

    @discardableResult
    /// Heavy enemy (tower, mass 20) — knocked back less.
    private func makeHeavyWeightEnemyEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyTagComponent(textureName: EnemyType.tower.textureName, scale: EnemyType.tower.scale), to: entity)
        world.addComponent(component: MassComponent(mass: EnemyType.tower.mass), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        return entity
    }

    @discardableResult
    /// Equal Mass enemy (equal, mass 10) — knocked back the same.
    private func makeSameWeightEnemyEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: EnemyTagComponent(textureName: EnemyType.mummy.textureName, scale: EnemyType.mummy.scale), to: entity)
        world.addComponent(component: MassComponent(mass: EnemyType.mummy.mass), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        return entity
    }

    @discardableResult
    /// Has VelocityComponent + PlayerTagComponent.
    private func makePlayerEntity(at position: SIMD2<Float>, size: SIMD2<Float>) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        world.addComponent(component: VelocityComponent(), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        world.addComponent(component: MassComponent(), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        return entity
    }

    // Creates an entity with the components required for collision testing.
    private func makeCollidableEntity(at position: SIMD2<Float>, size: SIMD2<Float>, rotation: Float = 0) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, rotation: rotation, scale: 1), to: entity)
        world.addComponent(component: CollisionBoxComponent(size: size), to: entity)
        return entity
    }

    // no collision when entities do not overlap

    func testNoCollisionWhenSeparated() {
        // Exactly touching (distance == sum of half-widths) is NOT a collision.
        XCTAssertFalse(collisionSystem.checkCollision(
            transformA: transformOrigin, boxA: smallBox,
            transformB: transformNear,   boxB: smallBox
        ))
    }


    func testNoCollisionWhenClearlyApart() {
        XCTAssertFalse(collisionSystem.checkCollision(
            transformA: transformOrigin, boxA: smallBox,
            transformB: transformFar,    boxB: smallBox
        ))
    }
    
    // collision detected when entities overlap

    func testCollisionWhenOverlapping() {
        // transformOverlapping is 5 apart from origin — boxes overlap by 5.
        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformOrigin,      boxA: smallBox,
            transformB: transformOverlapping, boxB: smallBox
        ))
    }
    
    func testCollisionWithDifferentBoxSize() {
        // A at (0,0) size (10,10): right edge at x=5
        // B at (10,0) size (20,20): left edge at x=0, overlap of 5
        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformOrigin, boxA: smallBox,
            transformB: transformNear,   boxB: largeBox
        ))
    }

    func testCollisionWithRotation() {
        // A at (0,0) size (10,10): right edge at x=5
        // B at (10,0) size (20,20) rotated 45 degrees: left edge extends to x=-5, overlap of 10
        XCTAssertTrue(collisionSystem.checkCollision(
            transformA: transformOrigin, boxA: smallBox,
            transformB: transformBRotated, boxB: largeBox
        ))
    }
    
    // MARK: dynamic vs static (wall)
     
    func test_playerHitsWall_onlyPlayerMoves() {
        let wall   = makeStaticEntity(at: SIMD2(15, 0), size: defaultBox)
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
 
        let wallPosBefore = world.getComponent(type: TransformComponent.self, for: wall)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let wallPosAfter   = world.getComponent(type: TransformComponent.self, for: wall)!.position
        let playerPosAfter = world.getComponent(type: TransformComponent.self, for: player)!.position
 
        XCTAssertEqual(wallPosAfter.x, wallPosBefore.x, accuracy: 0.001, "Wall must not move")
        XCTAssertEqual(wallPosAfter.y, wallPosBefore.y, accuracy: 0.001, "Wall must not move")
        XCTAssertNotEqual(playerPosAfter.x, 0, "Player should have been pushed")
    }
 
    func test_enemyHitsWall_onlyEnemyMoves() {
        let wall  = makeStaticEntity(at: SIMD2(15, 0), size: defaultBox)
        let enemy = makeLightWeightEnemyEntity( at: SIMD2(0,  0), size: defaultBox)
 
        let wallPosBefore = world.getComponent(type: TransformComponent.self, for: wall)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let wallPosAfter  = world.getComponent(type: TransformComponent.self, for: wall)!.position
        let enemyPosAfter = world.getComponent(type: TransformComponent.self, for: enemy)!.position
 
        XCTAssertEqual(wallPosAfter.x, wallPosBefore.x, accuracy: 0.001, "Wall must not move")
        XCTAssertEqual(wallPosAfter.y, wallPosBefore.y, accuracy: 0.001, "Wall must not move")
        XCTAssertNotEqual(enemyPosAfter.x, 0, "Enemy should have been pushed")
    }
 
    func test_wallVsWall_neitherMoves() {
        let wallA = makeStaticEntity(at: SIMD2(0,  0), size: defaultBox)
        let wallB = makeStaticEntity(at: SIMD2(15, 0), size: defaultBox)
 
        let posABefore = world.getComponent(type: TransformComponent.self, for: wallA)!.position
        let posBBefore = world.getComponent(type: TransformComponent.self, for: wallB)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        XCTAssertEqual(world.getComponent(type: TransformComponent.self, for: wallA)!.position.x, posABefore.x, accuracy: 0.001)
        XCTAssertEqual(world.getComponent(type: TransformComponent.self, for: wallB)!.position.x, posBBefore.x, accuracy: 0.001)
    }
 
    // MARK: player vs enemy
 
    func test_playerVsEnemy_bothReceiveKnockback() {
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemy  = makeLightWeightEnemyEntity( at: SIMD2(15, 0), size: defaultBox)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        XCTAssertNotNil(world.getComponent(type: KnockbackComponent.self, for: player), "Player should receive knockback")
        XCTAssertNotNil(world.getComponent(type: KnockbackComponent.self, for: enemy),  "Enemy should receive knockback")
    }
 
    func test_playerVsEnemy_knockbackDirectionsAreOpposite() {
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemy  = makeLightWeightEnemyEntity( at: SIMD2(15, 0), size: defaultBox)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let playerKB = world.getComponent(type: KnockbackComponent.self, for: player)!
        let enemyKB  = world.getComponent(type: KnockbackComponent.self, for: enemy)!
 
        XCTAssertTrue(playerKB.velocity.x * enemyKB.velocity.x < 0,
                      "Player and enemy knockback velocities should point in opposite directions")
    }
 
    // player (mass 10) vs light enemy (ranger, mass 5): enemy is lighter so gets displaced more
    func test_playerVsLightEnemy_enemyDisplacedMore() {
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemy  = makeLightWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)

        let playerPosBefore = world.getComponent(type: TransformComponent.self, for: player)!.position
        let enemyPosBefore  = world.getComponent(type: TransformComponent.self, for: enemy)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)

        let playerDisp = abs(world.getComponent(type: TransformComponent.self, for: player)!.position.x - playerPosBefore.x)
        let enemyDisp  = abs(world.getComponent(type: TransformComponent.self, for: enemy)!.position.x  - enemyPosBefore.x)

        XCTAssertGreaterThan(enemyDisp, playerDisp,
                             "Lighter enemy (ranger) should be displaced more than heavier player")
    }

    // player (mass 10) vs heavy enemy (tower, mass 20): player is lighter so gets displaced more
    func test_playerVsHeavyEnemy_playerDisplacedMore() {
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemy  = makeHeavyWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)

        let playerPosBefore = world.getComponent(type: TransformComponent.self, for: player)!.position
        let enemyPosBefore  = world.getComponent(type: TransformComponent.self, for: enemy)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)

        let playerDisp = abs(world.getComponent(type: TransformComponent.self, for: player)!.position.x - playerPosBefore.x)
        let enemyDisp  = abs(world.getComponent(type: TransformComponent.self, for: enemy)!.position.x  - enemyPosBefore.x)

        XCTAssertGreaterThan(playerDisp, enemyDisp,
                             "Player should be displaced more than heavier enemy (tower)")
    }

    // player (mass 10) vs same weight enemy (mummy, mass 10): displace equally
    func test_playerVsSameWeightEnemy_playerDisplacedEqually() {
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemy  = makeSameWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)

        let playerPosBefore = world.getComponent(type: TransformComponent.self, for: player)!.position
        let enemyPosBefore  = world.getComponent(type: TransformComponent.self, for: enemy)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)

        let playerDisp = abs(world.getComponent(type: TransformComponent.self, for: player)!.position.x - playerPosBefore.x)
        let enemyDisp  = abs(world.getComponent(type: TransformComponent.self, for: enemy)!.position.x  - enemyPosBefore.x)

        XCTAssertEqual(playerDisp, enemyDisp, accuracy: 0.001,
                             "Player should be displaced equally from same weight enemy (mummy)")
    }

    // light enemy (ranger, mass 5) receives high knockback speed from player collision
    func test_lightEnemyReceivesHighKnockbackSpeed() {
        makePlayerEntity(at: SIMD2(0, 0), size: defaultBox)
        let lightEnemy = makeLightWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)
        collisionSystem.update(deltaTime: 0.016, world: world)

        let lightKB = world.getComponent(type: KnockbackComponent.self, for: lightEnemy)!
        // ranger mass 5: knockbackSpeed = baseForce / 5 = 300
        XCTAssertEqual(simd_length(lightKB.velocity), 1500 / Float(EnemyType.ranger.mass), accuracy: 0.001,
                       "Light enemy (ranger) should receive knockback speed of baseForce / mass")
    }

    // heavy enemy (tower, mass 20) receives low knockback speed from player collision
    func test_heavyEnemyReceivesLowKnockbackSpeed() {
        makePlayerEntity(at: SIMD2(0, 0), size: defaultBox)
        let heavyEnemy = makeHeavyWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)
        collisionSystem.update(deltaTime: 0.016, world: world)

        let heavyKB = world.getComponent(type: KnockbackComponent.self, for: heavyEnemy)!
        // tower mass 20: knockbackSpeed = baseForce / 20 = 75
        XCTAssertEqual(simd_length(heavyKB.velocity), 1500 / Float(EnemyType.tower.mass), accuracy: 0.001,
                       "Heavy enemy (tower) should receive knockback speed of baseForce / mass")
    }

    // same weight enemy (mummy, mass 10) receives equal knockbackspeed as player
    // which should be 150
    func test_sameWeightEnemyReceivesSameKnockbackSpeed() {
        makePlayerEntity(at: SIMD2(0, 0), size: defaultBox)
        let sameWeightEnemy = makeSameWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)
        collisionSystem.update(deltaTime: 0.016, world: world)

        let sameWeightKB = world.getComponent(type: KnockbackComponent.self, for: sameWeightEnemy)!
        // mummy mass 10: knockbackSpeed = baseForce / 10 = 150
        XCTAssertEqual(simd_length(sameWeightKB.velocity), 1500 / Float(EnemyType.mummy.mass), accuracy: 0.001,
                       "Same Weight enemy (mummy) should receive knockback speed of baseForce / mass")
    }

    func test_playerVsEnemy_existingKnockbackNotOverwritten() {
        let player = makePlayerEntity(at: SIMD2(0,  0), size: defaultBox)
        _          = makeLightWeightEnemyEntity( at: SIMD2(15, 0), size: defaultBox)
 
        let existingVelocity = SIMD2<Float>(999, 0)
        world.addComponent(component: KnockbackComponent(velocity: existingVelocity, remainingTime: 1.0), to: player)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let kb = world.getComponent(type: KnockbackComponent.self, for: player)!
        XCTAssertEqual(kb.velocity.x, existingVelocity.x, accuracy: 0.001,
                       "Existing knockback should not be overwritten by a new collision")
    }
 
    // MARK: enemy vs enemy
 
    func test_enemyVsEnemy_equalDisplacement() {
        let enemyA = makeLightWeightEnemyEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemyB = makeLightWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)
 
        let posABefore = world.getComponent(type: TransformComponent.self, for: enemyA)!.position
        let posBBefore = world.getComponent(type: TransformComponent.self, for: enemyB)!.position
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        let dispA = abs(world.getComponent(type: TransformComponent.self, for: enemyA)!.position.x - posABefore.x)
        let dispB = abs(world.getComponent(type: TransformComponent.self, for: enemyB)!.position.x - posBBefore.x)
 
        XCTAssertEqual(dispA, dispB, accuracy: 0.001, "Both enemies should be displaced by equal amounts")
    }
 
    func test_enemyVsEnemy_noKnockbackApplied() {
        let enemyA = makeLightWeightEnemyEntity(at: SIMD2(0,  0), size: defaultBox)
        let enemyB = makeLightWeightEnemyEntity(at: SIMD2(15, 0), size: defaultBox)
 
        collisionSystem.update(deltaTime: 0.016, world: world)
 
        XCTAssertNil(world.getComponent(type: KnockbackComponent.self, for: enemyA), "Enemy-vs-enemy should not apply knockback")
        XCTAssertNil(world.getComponent(type: KnockbackComponent.self, for: enemyB), "Enemy-vs-enemy should not apply knockback")
    }
}
