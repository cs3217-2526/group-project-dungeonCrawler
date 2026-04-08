//
//  PickupSystemTests.swift
//  dungeonCrawlerTests
//
//  Created by Codex on 4/4/26.
//

import XCTest
import simd
@testable import dungeonCrawler

@MainActor
final class PickupSystemTests: XCTestCase {
    private var world: World!
    private var commandQueues: CommandQueues!
    private var system: PickupSystem!

    override func setUp() {
        super.setUp()
        world = World()
        commandQueues = CommandQueues()
        commandQueues.register(PickupCommand.self)
        system = PickupSystem(commandQueues: commandQueues)
    }

    override func tearDown() {
        system = nil
        commandQueues = nil
        world = nil
        super.tearDown()
    }

    func testPickupChoosesNearestDroppedWeaponWithinRange() {
        let (player, _) = makePlayer(at: .zero)
        let nearestWeapon = makeDroppedWeapon(at: SIMD2<Float>(20, 0))
        let fartherWeapon = makeDroppedWeapon(at: SIMD2<Float>(40, 0))

        commandQueues.push(PickupCommand(id: UUID()))
        system.update(deltaTime: 0.016, world: world)

        let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: player)
        XCTAssertEqual(equipped?.secondaryWeapon, nearestWeapon)
        XCTAssertEqual(world.getComponent(type: OwnerComponent.self, for: nearestWeapon)?.ownerEntity, player)
        XCTAssertNil(world.getComponent(type: SpriteComponent.self, for: nearestWeapon))
        XCTAssertNil(world.getComponent(type: OwnerComponent.self, for: fartherWeapon))
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: fartherWeapon))
    }

    func testPickupSkipsWeaponsOutsidePickupRange() {
        let (player, _) = makePlayer(at: .zero)
        let distantWeapon = makeDroppedWeapon(at: SIMD2<Float>(100, 0))

        commandQueues.push(PickupCommand(id: UUID()))
        system.update(deltaTime: 0.016, world: world)

        let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: player)
        XCTAssertNil(equipped?.secondaryWeapon)
        XCTAssertNil(world.getComponent(type: OwnerComponent.self, for: distantWeapon))
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: distantWeapon))
    }

    private func makePlayer(at position: SIMD2<Float>) -> (player: Entity, primaryWeapon: Entity) {
        let player = world.createEntity()
        world.addComponent(component: PlayerTagComponent(), to: player)
        world.addComponent(component: TransformComponent(position: position), to: player)
        world.addComponent(component: FacingComponent(facing: .right), to: player)

        let primaryWeapon = world.createEntity()
        world.addComponent(
            component: OwnerComponent(ownerEntity: player, offset: SIMD2<Float>(10, -5)),
            to: primaryWeapon
        )

        world.addComponent(
            component: EquippedWeaponComponent(primaryWeapon: primaryWeapon, secondaryWeapon: nil),
            to: player
        )

        return (player, primaryWeapon)
    }

    private func makeDroppedWeapon(at position: SIMD2<Float>) -> Entity {
        let weapon = world.createEntity()
        world.addComponent(component: TransformComponent(position: position), to: weapon)
        world.addComponent(
            component: SpriteComponent(content: .texture(name: "handgun"), layer: .weapon),
            to: weapon
        )
        world.addComponent(
            component: WeaponTimingComponent(lastFiredAt: 0, coolDownInterval: nil, attackSpeed: nil),
            to: weapon
        )
        world.addComponent(
            component: WeaponRenderComponent(
                textureName: "handgun",
                anchorPoint: SIMD2<Float>(0.5, 0.5),
                initRotation: 0
            ),
            to: weapon
        )
        world.addComponent(component: WeaponEffectsComponent(effects: []), to: weapon)
        return weapon
    }
}
