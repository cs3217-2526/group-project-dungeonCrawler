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

    var world: World!
    var commandQueues: CommandQueues!
    var system: PickupSystem!

    // Player entities and components
    var playerEntity: Entity!
    var playerTransform: TransformComponent!
    var playerFacing: FacingComponent!
    var playerTag: PlayerTagComponent!
    var primaryWeapon: Entity!
    var primaryWeaponOwner: OwnerComponent!
    var equippedWeapon: EquippedWeaponComponent!

    // Near dropped weapon entities and components
    var nearWeaponEntity: Entity!
    var nearWeaponTransform: TransformComponent!
    var nearWeaponSprite: SpriteComponent!
    var nearWeaponTiming: WeaponTimingComponent!
    var nearWeaponRender: WeaponRenderComponent!
    var nearWeaponEffects: WeaponEffectsComponent!

    // Far dropped weapon entities and components
    var farWeaponEntity: Entity!
    var farWeaponTransform: TransformComponent!
    var farWeaponSprite: SpriteComponent!
    var farWeaponTiming: WeaponTimingComponent!
    var farWeaponRender: WeaponRenderComponent!
    var farWeaponEffects: WeaponEffectsComponent!
    
    var outOfRange1: TransformComponent!
    var outOfRange2: TransformComponent!

    static let defaultPlayerPosition: SIMD2<Float>   = .zero
    static let defaultNearWeaponPosition: SIMD2<Float> = SIMD2(20, 0)
    static let defaultFarWeaponPosition: SIMD2<Float>  = SIMD2(40, 0)
    static let defaultOutOfRangePosition: SIMD2<Float> = SIMD2(100, 0)

    override func setUp() {
        super.setUp()
        world         = World()
        commandQueues = CommandQueues()
        commandQueues.register(PickupCommand.self)
        system = PickupSystem(commandQueues: commandQueues)

        // --- Player ---
        playerTag       = PlayerTagComponent()
        playerTransform = TransformComponent(position: Self.defaultPlayerPosition)
        playerFacing    = FacingComponent(facing: .right)

        playerEntity = world.createEntity()
        world.addComponent(component: playerTag,       to: playerEntity)
        world.addComponent(component: playerTransform, to: playerEntity)
        world.addComponent(component: playerFacing,    to: playerEntity)

        primaryWeaponOwner = OwnerComponent(ownerEntity: playerEntity, offset: SIMD2<Float>(10, -5))
        primaryWeapon = world.createEntity()
        world.addComponent(component: primaryWeaponOwner, to: primaryWeapon)

        equippedWeapon = EquippedWeaponComponent(primaryWeapon: primaryWeapon, secondaryWeapon: nil)
        world.addComponent(component: equippedWeapon, to: playerEntity)

        // --- Near dropped weapon (within pickup range) ---
        nearWeaponTransform = TransformComponent(position: Self.defaultNearWeaponPosition)
        nearWeaponSprite    = SpriteComponent(content: .texture(name: "handgun"), layer: .weapon)
        nearWeaponTiming    = WeaponTimingComponent(lastFiredAt: 0, coolDownInterval: nil, attackSpeed: nil)
        nearWeaponRender    = WeaponRenderComponent(
            textureName: "handgun",
            anchorPoint: SIMD2<Float>(0.5, 0.5),
            initRotation: 0
        )
        nearWeaponEffects = WeaponEffectsComponent(effects: [])

        nearWeaponEntity = world.createEntity()
        world.addComponent(component: nearWeaponTransform, to: nearWeaponEntity)
        world.addComponent(component: nearWeaponSprite,    to: nearWeaponEntity)
        world.addComponent(component: nearWeaponTiming,    to: nearWeaponEntity)
        world.addComponent(component: nearWeaponRender,    to: nearWeaponEntity)
        world.addComponent(component: nearWeaponEffects,   to: nearWeaponEntity)

        // --- Far dropped weapon (also within pickup range, but farther) ---
        farWeaponTransform = TransformComponent(position: Self.defaultFarWeaponPosition)
        farWeaponSprite    = SpriteComponent(content: .texture(name: "handgun"), layer: .weapon)
        farWeaponTiming    = WeaponTimingComponent(lastFiredAt: 0, coolDownInterval: nil, attackSpeed: nil)
        farWeaponRender    = WeaponRenderComponent(
            textureName: "handgun",
            anchorPoint: SIMD2<Float>(0.5, 0.5),
            initRotation: 0
        )
        farWeaponEffects = WeaponEffectsComponent(effects: [])

        farWeaponEntity = world.createEntity()
        world.addComponent(component: farWeaponTransform, to: farWeaponEntity)
        world.addComponent(component: farWeaponSprite,    to: farWeaponEntity)
        world.addComponent(component: farWeaponTiming,    to: farWeaponEntity)
        world.addComponent(component: farWeaponRender,    to: farWeaponEntity)
        world.addComponent(component: farWeaponEffects,   to: farWeaponEntity)
        
        outOfRange1 = TransformComponent(position: Self.defaultOutOfRangePosition)
        outOfRange2 = TransformComponent(position: Self.defaultOutOfRangePosition)
    }

    override func tearDown() {
        playerEntity        = nil
        playerTransform     = nil
        playerFacing        = nil
        playerTag           = nil
        primaryWeapon       = nil
        primaryWeaponOwner  = nil
        equippedWeapon      = nil
        nearWeaponEntity    = nil
        nearWeaponTransform = nil
        nearWeaponSprite    = nil
        nearWeaponTiming    = nil
        nearWeaponRender    = nil
        nearWeaponEffects   = nil
        farWeaponEntity     = nil
        farWeaponTransform  = nil
        farWeaponSprite     = nil
        farWeaponTiming     = nil
        farWeaponRender     = nil
        farWeaponEffects    = nil
        outOfRange1         = nil
        outOfRange2         = nil
        system              = nil
        commandQueues       = nil
        world               = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testPickupChoosesNearestDroppedWeaponWithinRange() {
        commandQueues.push(PickupCommand(id: UUID()))
        system.update(deltaTime: 0.016, world: world)

        let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: playerEntity)
        XCTAssertEqual(equipped?.secondaryWeapon, nearWeaponEntity)
        XCTAssertEqual(world.getComponent(type: OwnerComponent.self, for: nearWeaponEntity)?.ownerEntity, playerEntity)
        XCTAssertNil(world.getComponent(type: SpriteComponent.self, for: nearWeaponEntity))
        XCTAssertNil(world.getComponent(type: OwnerComponent.self, for: farWeaponEntity))
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: farWeaponEntity))
    }

    func testPickupSkipsWeaponsOutsidePickupRange() {
        // Move the near weapon out of range so neither weapon is reachable
        world.addComponent(component: outOfRange1, to: nearWeaponEntity)
        world.addComponent(component: outOfRange2, to: farWeaponEntity)

        commandQueues.push(PickupCommand(id: UUID()))
        system.update(deltaTime: 0.016, world: world)

        let equipped = world.getComponent(type: EquippedWeaponComponent.self, for: playerEntity)
        XCTAssertNil(equipped?.secondaryWeapon)
        XCTAssertNil(world.getComponent(type: OwnerComponent.self, for: nearWeaponEntity))
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: nearWeaponEntity))
        XCTAssertNil(world.getComponent(type: OwnerComponent.self, for: farWeaponEntity))
        XCTAssertNotNil(world.getComponent(type: SpriteComponent.self, for: farWeaponEntity))
    }
}
