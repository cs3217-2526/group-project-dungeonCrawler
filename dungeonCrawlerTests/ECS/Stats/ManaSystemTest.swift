//
//  ManaSystemTest.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 31/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class ManaSystemTests: XCTestCase {

    var world: World!
    var system: ManaSystem!
    var entity1: Entity!
    var entity2: Entity!
    var mana1: ManaComponent!
    var mana2: ManaComponent!
    var fastRegen: ManaComponent!
    var nearMax: ManaComponent!
    var maxedMana: ManaComponent!
    var noRegen: ManaComponent!
    var defaultRegen: ManaComponent!
    var transform: TransformComponent!

    override func setUp() {
        super.setUp()
        world   = World()
        system  = ManaSystem()
        entity1 = world.createEntity()
        entity2 = world.createEntity()
        
        // Default components for general testing
        mana1 = ManaComponent(base: 0, max: 100, regenRate: 10)
        mana2 = ManaComponent(base: 0, max: 100, regenRate: 25)
        fastRegen = ManaComponent(base: 0, max: 100, regenRate: 20)
        nearMax = ManaComponent(base: 90, max: 100, regenRate: 20)
        maxedMana = ManaComponent(base: 100, max: 100, regenRate: 10)
        noRegen = ManaComponent(base: 50, max: 100, regenRate: 0)
        defaultRegen = ManaComponent(base: 40, max: 100) // regenRate defaults to 0
        transform = TransformComponent()
    }

    override func tearDown() {
        world   = nil
        system  = nil
        entity1 = nil
        entity2 = nil
        mana1   = nil
        mana2   = nil
        fastRegen = nil
        nearMax = nil
        maxedMana = nil
        noRegen = nil
        defaultRegen = nil
        transform = nil
        super.tearDown()
    }

    // MARK: - Regen applies correctly

    func testManaIncreasesEachFrameWhenBelowMax() {
        world.addComponent(component: mana1, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 10, accuracy: 0.001)
    }

    func testManaRegenScalesWithDeltaTime() {
        world.addComponent(component: fastRegen, to: entity1)

        system.update(deltaTime: 0.5, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 10, accuracy: 0.001)
    }

    func testManaAccumulatesOverMultipleFrames() {
        world.addComponent(component: mana1, to: entity1)

        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 1.0, world: world)
        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 30, accuracy: 0.001)
    }

    // MARK: - Clamping to max

    func testManaDoesNotExceedMax() {
        world.addComponent(component: nearMax, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 100, accuracy: 0.001)
    }

    func testManaAlreadyAtMaxDoesNotChange() {
        world.addComponent(component: maxedMana, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 100, accuracy: 0.001)
    }

    // MARK: - Zero regen rate

    func testZeroRegenRateDoesNotChangeMana() {
        world.addComponent(component: noRegen, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 50, accuracy: 0.001)
    }

    func testDefaultRegenRateIsZero() {
        world.addComponent(component: defaultRegen, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        let mana = world.getComponent(type: ManaComponent.self, for: entity1)!
        XCTAssertEqual(mana.value.current, 40, accuracy: 0.001)
    }

    // MARK: - Multiple entities handled independently

    func testMultipleEntitiesRegenIndependently() {
        world.addComponent(component: mana1, to: entity1) // Rate 10
        world.addComponent(component: mana2, to: entity2) // Rate 25

        system.update(deltaTime: 1.0, world: world)

        let m1 = world.getComponent(type: ManaComponent.self, for: entity1)!
        let m2 = world.getComponent(type: ManaComponent.self, for: entity2)!
        XCTAssertEqual(m1.value.current, 10, accuracy: 0.001)
        XCTAssertEqual(m2.value.current, 25, accuracy: 0.001)
    }

    func testEntityWithZeroRegenUnaffectedAlongsideRegenEntity() {
        world.addComponent(component: mana1, to: entity1)
        world.addComponent(component: noRegen, to: entity2)

        system.update(deltaTime: 1.0, world: world)

        let m1 = world.getComponent(type: ManaComponent.self, for: entity1)!
        let m2 = world.getComponent(type: ManaComponent.self, for: entity2)!
        XCTAssertEqual(m1.value.current, 10, accuracy: 0.001)
        XCTAssertEqual(m2.value.current, 50, accuracy: 0.001)
    }

    // MARK: - Edge cases

    func testEntityWithoutManaComponentUnaffected() {
        world.addComponent(component: transform, to: entity1)

        system.update(deltaTime: 1.0, world: world)

        XCTAssertNotNil(world.getComponent(type: TransformComponent.self, for: entity1))
    }

    func testEmptyWorldDoesNotCrash() {
        world.destroyAllEntities()
        system.update(deltaTime: 0.016, world: world)
    }
}
