//
//  ProjectileSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Letian on 20/3/26.
//

import Foundation
import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class ProjectileSystemTests: XCTestCase {
    
    var world: World!
    var system: ProjectileSystem!
    let collisionEvents   = CollisionEventBuffer()
    let destructionQueue  = DestructionQueue()
    
    override func setUp() {
        super.setUp()
        world = World()
        system = ProjectileSystem(events: collisionEvents,  destructionQueue: destructionQueue)
    }
    
    override func tearDown() {
        world = nil
        system = nil
        super.tearDown()
    }
    
    static let defaultVelocity: Float = 300
    static let defaultEffectiveRange: Float = 300
    
    /// default velocity is 300
    /// default projectile effective range is 300
    @discardableResult
    private func makeProjectile(from position: SIMD2<Float> = SIMD2(0, 0),
                                aimAt direction: SIMD2<Float> = SIMD2(1, 0)) -> Entity {
        let speed: Float = ProjectileSystemTests.defaultVelocity
        let owner = world.createEntity()
        let projectile = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: projectile)
        world.addComponent(component: VelocityComponent(linear: direction * speed), to: projectile)
        world.addComponent(component: SpriteComponent(textureName: "normalHandgunBullet", zPosition: 5), to: projectile)
        world.addComponent(component: ProjectileComponent(damage: 10, owner: owner), to: projectile)
        world.addComponent(component: EffectiveRangeComponent(base: ProjectileSystemTests.defaultEffectiveRange), to: projectile)
        return projectile
    }
    
    func testProjectileEffectiveRangeDecreaseByTime() {
        let projectile = makeProjectile()
        system.update(deltaTime: 0.1, world: world)
        let effectiveRangeAfter = world.getComponent(type: EffectiveRangeComponent.self, for: projectile)!.value.current
        XCTAssertEqual(effectiveRangeAfter, ProjectileSystemTests.defaultEffectiveRange - ProjectileSystemTests.defaultVelocity * 0.1, accuracy: 0.001)
    }
    
    func testProjectileDestroyedAfterEffectiveRangeBecomeZero() {
        let projectile = makeProjectile()
        system.update(deltaTime: 5, world: world)
        let projectileAfter = world.getComponent(type: ProjectileComponent.self, for: projectile) ?? nil
        XCTAssertNil(projectileAfter)
    }
    
    func testProjectileDestroyedAfterEffectiveRangeBecomeZeroAndAfter() {
        let projectile = makeProjectile()
        system.update(deltaTime: 1.1, world: world)
        let projectileAfter = world.getComponent(type: ProjectileComponent.self, for: projectile) ?? nil
        XCTAssertNil(projectileAfter)
    }
    
    func testProjectileNotDestroyedWhenEffectiveRangeLargerThanZero() {
        let projectile = makeProjectile()
        system.update(deltaTime: 0.9, world: world)
        let projectileAfter = world.getComponent(type: ProjectileComponent.self, for: projectile) ?? nil
        XCTAssertNotNil(projectileAfter)
    }
}
