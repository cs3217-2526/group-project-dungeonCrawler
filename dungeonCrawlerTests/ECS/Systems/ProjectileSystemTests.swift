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
    var collisionEvents: CollisionEventBuffer!
    var destructionQueue: DestructionQueue!
    
    // Properties for tracked entities and components
    var projectileEntity: Entity!
    var transform: TransformComponent!
    var velocity: VelocityComponent!
    var projectileComp: ProjectileComponent!
    var effectiveRange: EffectiveRangeComponent!
    var contactDamage: ContactDamageComponent!
    var sprite: SpriteComponent!
    
    static let defaultVelocity: Float = 300
    static let defaultEffectiveRange: Float = 300
    static let defaultDamage: Float = 10
    
    override func setUp() {
        super.setUp()
        world            = World()
        collisionEvents  = CollisionEventBuffer()
        destructionQueue = DestructionQueue()
        system           = ProjectileSystem(events: collisionEvents, destructionQueue: destructionQueue)
        transform      = TransformComponent(position: SIMD2(0, 0), scale: 1)
        velocity       = VelocityComponent(linear: SIMD2(1, 0) * Self.defaultVelocity)
        projectileComp = ProjectileComponent(hitEffects: [])
        effectiveRange = EffectiveRangeComponent(base: Self.defaultEffectiveRange)
        contactDamage  = ContactDamageComponent(damage: 10)
        sprite = SpriteComponent(textureName: "normalHandgunBullet", zPosition: 5)
        
        // Initialize the default projectile using the helper
        projectileEntity = world.createEntity()
        world.addComponent(component: transform, to: projectileEntity)
        world.addComponent(component: velocity, to: projectileEntity)
        world.addComponent(component: sprite, to: projectileEntity)
        world.addComponent(component: projectileComp, to: projectileEntity)
        world.addComponent(component: effectiveRange, to: projectileEntity)
        world.addComponent(component: contactDamage, to: projectileEntity)
        
    }
    
    override func tearDown() {
        world            = nil
        system           = nil
        collisionEvents  = nil
        destructionQueue = nil
        projectileEntity = nil
        transform        = nil
        velocity         = nil
        projectileComp   = nil
        effectiveRange   = nil
        contactDamage    = nil
        sprite = nil
        super.tearDown()
    }
    
    // MARK: - Tests
     
    func testProjectileEffectiveRangeDecreaseByTime() {
        system.update(deltaTime: 0.1, world: world)
        
        // We can now check the property directly instead of calling world.getComponent
        XCTAssertEqual(
            effectiveRange.value.current,
            Self.defaultEffectiveRange - Self.defaultVelocity * 0.1,
            accuracy: 0.001
        )
    }
 
    func testProjectileDestroyedAfterEffectiveRangeReachesZero() {
        system.update(deltaTime: 5, world: world)
        
        // Verification that it was removed from world
        XCTAssertNil(world.getComponent(type: ProjectileComponent.self, for: projectileEntity))
    }
 
    func testProjectileComponentHasCorrectDamage() {
        // Verification via the class property
        XCTAssertEqual(contactDamage.damage, 10, accuracy: 0.001)
    }
    
    func testProjectileContactDamageUnchangedAfterRangeDecay() {
        system.update(deltaTime: 0.5, world: world)
        XCTAssertEqual(contactDamage.damage, 10, accuracy: 0.001)
    }
}
