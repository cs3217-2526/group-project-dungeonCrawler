//
//  DamageSystemTest.swift
//  dungeonCrawlerTests
//
//  Created by Jannice Suciptono on 30/3/26.
//

import Foundation
import XCTest
@testable import dungeonCrawler

final class DamageSystemTests: XCTestCase {

    var world: World!
    var events: CollisionEventBuffer!
    var system: DamageSystem!
    var destructionQueue: DestructionQueue!

    override func setUp() {
        super.setUp()
        world  = World()
        events = CollisionEventBuffer()
        destructionQueue = DestructionQueue()
        system = DamageSystem(events: events, destructionQueue: destructionQueue)
    }

    override func tearDown() {
        system = nil
        events = nil
        destructionQueue = nil
        world  = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Creates a live player entity with health and returns it.
    private func makePlayer(hp: Float = 100) -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: HealthComponent(base: hp), to: entity)
        world.addComponent(component: PlayerTagComponent(), to: entity)
        return entity
    }

    /// Creates a dummy enemy entity and returns it.
    private func makeEnemy() -> Entity {
        let entity = world.createEntity()
        world.addComponent(component: EnemyTagComponent(textureName: "Mummy", scale: 1.0), to: entity)
        world.addComponent(component: HealthComponent(base: 100), to: entity)
        return entity
    }

    /// Records a hit event directly into the shared buffer.
    private func recordHit(player: Entity, enemy: Entity, damage: Float) {
        events.recordPlayerHitByEnemy(player: player, enemy: enemy, damage: damage)
    }

    // MARK: - Basic damage application

    func testDamageReducesPlayerHealth() {
        let player = makePlayer(hp: 100)
        let enemy  = makeEnemy()
        recordHit(player: player, enemy: enemy, damage: 20)

        system.update(deltaTime: 0.016, world: world)

        let health = world.getComponent(type: HealthComponent.self, for: player)
        XCTAssertEqual(health!.value.current, 80, accuracy: 0.001)
    }

    func testDamageDoesNotGoBelowZero() {
        let player = makePlayer(hp: 10)
        let enemy  = makeEnemy()
        recordHit(player: player, enemy: enemy, damage: 999)

        system.update(deltaTime: 0.016, world: world)

        let health = world.getComponent(type: HealthComponent.self, for: player)
        XCTAssertEqual(health!.value.current, 0, accuracy: 0.001)
    }

    func testFullDamageAppliedExactly() {
        let player = makePlayer(hp: 50)
        let enemy  = makeEnemy()
        recordHit(player: player, enemy: enemy, damage: 50)

        system.update(deltaTime: 0.016, world: world)

        let health = world.getComponent(type: HealthComponent.self, for: player)
        XCTAssertEqual(health!.value.current, 0, accuracy: 0.001)
    }

    // MARK: - Invincibility frames granted after hit

    func testInvincibilityComponentAddedAfterDamage() {
        let player = makePlayer()
        let enemy  = makeEnemy()
        recordHit(player: player, enemy: enemy, damage: 10)

        system.update(deltaTime: 0.016, world: world)

        XCTAssertNotNil(world.getComponent(type: InvincibilityComponent.self, for: player))
    }

    func testInvincibilityPreventsSecondHitSameFrame() {
        let player = makePlayer(hp: 100)
        let enemy  = makeEnemy()
        // Two events in the same frame
        recordHit(player: player, enemy: enemy, damage: 20)
        recordHit(player: player, enemy: enemy, damage: 20)

        system.update(deltaTime: 0.016, world: world)

        // Only the first hit should have landed
        let health = world.getComponent(type: HealthComponent.self, for: player)
        XCTAssertEqual(health!.value.current, 80, accuracy: 0.001)
    }

    func testEntityAlreadyInvincibleTakeNoDamage() {
        let player = makePlayer(hp: 100)
        let enemy  = makeEnemy()
        // Pre-attach invincibility
        world.addComponent(component: InvincibilityComponent(remainingTime: 0.5), to: player)
        recordHit(player: player, enemy: enemy, damage: 30)

        system.update(deltaTime: 0.016, world: world)

        let health = world.getComponent(type: HealthComponent.self, for: player)
        XCTAssertEqual(health!.value.current, 100, accuracy: 0.001)
    }

    // MARK: - Dead entity guard

    func testNoEventsMeansNoHealthChange() {
        let player = makePlayer(hp: 100)
        // No events recorded

        system.update(deltaTime: 0.016, world: world)

        let health = world.getComponent(type: HealthComponent.self, for: player)
        XCTAssertEqual(health!.value.current, 100, accuracy: 0.001)
    }

    func testDeadEntityIsSkipped() {
        let player = makePlayer(hp: 100)
        let enemy  = makeEnemy()
        recordHit(player: player, enemy: enemy, damage: 20)

        // Destroy the player before the system runs
        world.destroyEntity(entity: player)

        // Should not crash
        system.update(deltaTime: 0.016, world: world)
    }

    // MARK: - Multiple players / events

    func testDamageAppliedToCorrectPlayer() {
        let playerA = makePlayer(hp: 100)
        let playerB = makePlayer(hp: 100)
        let enemy   = makeEnemy()
        recordHit(player: playerA, enemy: enemy, damage: 25)

        system.update(deltaTime: 0.016, world: world)

        let healthA = world.getComponent(type: HealthComponent.self, for: playerA)
        let healthB = world.getComponent(type: HealthComponent.self, for: playerB)
        XCTAssertEqual(healthA!.value.current, 75, accuracy: 0.001)
        XCTAssertEqual(healthB!.value.current, 100, accuracy: 0.001)
    }

    func testEmptyEventBufferDoesNotCrash() {
        system.update(deltaTime: 0.016, world: world)
    }

    func testEmptyWorldDoesNotCrash() {
        recordHit(player: Entity(), enemy: Entity(), damage: 10)
        system.update(deltaTime: 0.016, world: world)
    }
}
