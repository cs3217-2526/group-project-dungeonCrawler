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
    static let defaultDamage: Float = 10
    
    /// default velocity is 300
    /// default projectile effective range is 300
    @discardableResult
    private func makeProjectile(from position: SIMD2<Float> = SIMD2(0, 0),
                                aimAt direction: SIMD2<Float> = SIMD2(1, 0),
                                damage: Float = 10) -> Entity {
        let speed: Float = ProjectileSystemTests.defaultVelocity
        let projectile = world.createEntity()
        world.addComponent(component: TransformComponent(position: position, scale: 1), to: projectile)
        world.addComponent(component: VelocityComponent(linear: direction * speed), to: projectile)
        world.addComponent(component: SpriteComponent(textureName: "normalHandgunBullet", zPosition: 5), to: projectile)
        world.addComponent(component: ProjectileComponent(), to: projectile)
        world.addComponent(component: EffectiveRangeComponent(base: Self.defaultEffectiveRange), to: projectile)
        world.addComponent(component: ContactDamageComponent(damage: damage), to: projectile)
        return projectile
    }
    
    // MARK: - Effective range
     
    func testProjectileEffectiveRangeDecreaseByTime() {
        let projectile = makeProjectile()
        system.update(deltaTime: 0.1, world: world)
        let rangeAfter = world.getComponent(type: EffectiveRangeComponent.self, for: projectile)!.value.current
        XCTAssertEqual(
            rangeAfter,
            Self.defaultEffectiveRange - Self.defaultVelocity * 0.1,
            accuracy: 0.001
        )
    }
 
    func testProjectileDestroyedAfterEffectiveRangeReachesZero() {
        let projectile = makeProjectile()
        system.update(deltaTime: 5, world: world)
        XCTAssertNil(world.getComponent(type: ProjectileComponent.self, for: projectile))
    }
 
    func testProjectileDestroyedJustPastEffectiveRange() {
        let projectile = makeProjectile()
        system.update(deltaTime: 1.1, world: world)
        XCTAssertNil(world.getComponent(type: ProjectileComponent.self, for: projectile))
    }
 
    func testProjectileNotDestroyedWhenEffectiveRangeStillPositive() {
        let projectile = makeProjectile()
        system.update(deltaTime: 0.9, world: world)
        XCTAssertNotNil(world.getComponent(type: ProjectileComponent.self, for: projectile))
    }
 
    // MARK: - Component values
 
    func testProjectileComponentHasCorrectDamage() {
        let projectile = makeProjectile(damage: 42)
        let comp = world.getComponent(type: ContactDamageComponent.self, for: projectile)!
        XCTAssertEqual(comp.damage, 42, accuracy: 0.001)
    }
 
    func testProjectileContactDamageUnchangedAfterRangeDecay() {
        let projectile = makeProjectile(damage: 30)
        system.update(deltaTime: 0.5, world: world)
        let comp = world.getComponent(type: ContactDamageComponent.self, for: projectile)!
        XCTAssertEqual(comp.damage, 30, accuracy: 0.001)
    }
}
