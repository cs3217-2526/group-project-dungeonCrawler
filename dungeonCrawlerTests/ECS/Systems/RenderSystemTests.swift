import XCTest
import simd
@testable import dungeonCrawler

// MARK: - Mock

final class MockRenderingBackend: RenderingBackend {
    struct SyncCall {
        let entity: Entity
        let health: HealthComponent?
        let hasDirectionalAnimation: Bool
    }

    var syncCalls:   [SyncCall] = []
    var removeCalls: [Entity]   = []

    func syncNode(
        for entity: Entity,
        transform: TransformComponent,
        sprite: SpriteComponent,
        facing: FacingComponent?,
        velocity: VelocityComponent?,
        health: HealthComponent?,
        hasDirectionalAnimation: Bool
    ) {
        syncCalls.append(SyncCall(entity: entity, health: health,
                                  hasDirectionalAnimation: hasDirectionalAnimation))
    }

    func removeNode(for entity: Entity) {
        removeCalls.append(entity)
    }
}

// MARK: - Tests

@MainActor
final class RenderSystemTests: XCTestCase {

    var world:   World!
    var backend: MockRenderingBackend!
    var system:  RenderSystem!

    // MARK: - Entities

    var renderableEntity:  Entity!
    var renderableEntity2: Entity!
    var renderableEntity3: Entity!

    var noSpriteEntity:    Entity!
    var noTransformEntity: Entity!

    var playerEntity:      Entity!
    var enemyEntity:       Entity!
    var animatedEntity:    Entity!

    // MARK: - Components

    var renderableTransform:  TransformComponent!
    var renderableSprite:     SpriteComponent!
    var renderableTransform2: TransformComponent!
    var renderableSprite2:    SpriteComponent!
    var renderableTransform3: TransformComponent!
    var renderableSprite3:    SpriteComponent!

    var noSpriteTransform:    TransformComponent!
    var noTransformSprite:    SpriteComponent!

    var playerTransform:      TransformComponent!
    var playerSprite:         SpriteComponent!
    var playerTag:            PlayerTagComponent!
    var playerHealth:         HealthComponent!

    var enemyTransform:       TransformComponent!
    var enemySprite:          SpriteComponent!
    var enemyHealth:          HealthComponent!

    var animatedTransform:    TransformComponent!
    var animatedSprite:       SpriteComponent!
    var animationComp:        AnimationComponent!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        world   = World()
        backend = MockRenderingBackend()
        system  = RenderSystem(backend: backend)

        renderableTransform  = TransformComponent(position: .zero)
        renderableSprite     = SpriteComponent(textureName: "test")
        renderableTransform2 = TransformComponent(position: .zero)
        renderableSprite2    = SpriteComponent(textureName: "test2")
        renderableTransform3 = TransformComponent(position: .zero)
        renderableSprite3    = SpriteComponent(textureName: "test3")

        noSpriteTransform    = TransformComponent(position: .zero)
        noTransformSprite    = SpriteComponent(textureName: "no_transform")

        playerTransform      = TransformComponent(position: .zero)
        playerSprite         = SpriteComponent(textureName: "player")
        playerTag            = PlayerTagComponent()
        playerHealth         = HealthComponent(base: 100, max: 100)

        enemyTransform       = TransformComponent(position: .zero)
        enemySprite          = SpriteComponent(textureName: "enemy")
        enemyHealth          = HealthComponent(base: 50, max: 100)

        animatedTransform    = TransformComponent(position: .zero)
        animatedSprite       = SpriteComponent(textureName: "animated")
        animationComp        = AnimationComponent(animations: ["idleDown": []], frameDuration: 0.1)

        renderableEntity = world.createEntity()
        world.addComponent(component: renderableTransform, to: renderableEntity)
        world.addComponent(component: renderableSprite,    to: renderableEntity)

        renderableEntity2 = world.createEntity()
        world.addComponent(component: renderableTransform2, to: renderableEntity2)
        world.addComponent(component: renderableSprite2,    to: renderableEntity2)

        renderableEntity3 = world.createEntity()
        world.addComponent(component: renderableTransform3, to: renderableEntity3)
        world.addComponent(component: renderableSprite3,    to: renderableEntity3)

        noSpriteEntity = world.createEntity()
        world.addComponent(component: noSpriteTransform, to: noSpriteEntity)

        noTransformEntity = world.createEntity()
        world.addComponent(component: noTransformSprite, to: noTransformEntity)

        playerEntity = world.createEntity()
        world.addComponent(component: playerTransform, to: playerEntity)
        world.addComponent(component: playerSprite,    to: playerEntity)
        world.addComponent(component: playerTag,       to: playerEntity)
        world.addComponent(component: playerHealth,    to: playerEntity)

        enemyEntity = world.createEntity()
        world.addComponent(component: enemyTransform, to: enemyEntity)
        world.addComponent(component: enemySprite,    to: enemyEntity)
        world.addComponent(component: enemyHealth,    to: enemyEntity)

        animatedEntity = world.createEntity()
        world.addComponent(component: animatedTransform, to: animatedEntity)
        world.addComponent(component: animatedSprite,    to: animatedEntity)
        world.addComponent(component: animationComp,     to: animatedEntity)
    }

    override func tearDown() {
        world             = nil
        backend           = nil
        system            = nil
        renderableEntity  = nil
        renderableEntity2 = nil
        renderableEntity3 = nil
        noSpriteEntity    = nil
        noTransformEntity = nil
        playerEntity      = nil
        enemyEntity       = nil
        animatedEntity    = nil
        renderableTransform  = nil
        renderableSprite     = nil
        renderableTransform2 = nil
        renderableSprite2    = nil
        renderableTransform3 = nil
        renderableSprite3    = nil
        noSpriteTransform    = nil
        noTransformSprite    = nil
        playerTransform      = nil
        playerSprite         = nil
        playerTag            = nil
        playerHealth         = nil
        enemyTransform       = nil
        enemySprite          = nil
        enemyHealth          = nil
        animatedTransform    = nil
        animatedSprite       = nil
        animationComp        = nil
        super.tearDown()
    }

    // MARK: - Sync behaviour

    func testEntityWithBothComponentsGetsSynced() {
        system.update(deltaTime: 0.016, world: world)

        let synced = backend.syncCalls.map { $0.entity }
        XCTAssertTrue(synced.contains(renderableEntity))
    }

    func testEntityWithoutSpriteComponentIsNotSynced() {
        system.update(deltaTime: 0.016, world: world)

        let synced = backend.syncCalls.map { $0.entity }
        XCTAssertFalse(synced.contains(noSpriteEntity))
    }

    func testEntityWithoutTransformComponentIsNotSynced() {
        system.update(deltaTime: 0.016, world: world)

        let synced = backend.syncCalls.map { $0.entity }
        XCTAssertFalse(synced.contains(noTransformEntity))
    }

    func testMultipleRenderableEntitiesAllGetSynced() {
        system.update(deltaTime: 0.016, world: world)

        let synced = backend.syncCalls.map { $0.entity }
        XCTAssertTrue(synced.contains(renderableEntity))
        XCTAssertTrue(synced.contains(renderableEntity2))
        XCTAssertTrue(synced.contains(renderableEntity3))
    }

    func testCorrectEntityIsPassedToBackend() {
        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.syncCalls.contains { $0.entity == renderableEntity })
    }

    // MARK: - Stale entity removal

    func testEntityThatLosesSpriteComponentGetsRemoveNodeCalledNextFrame() {
        system.update(deltaTime: 0.016, world: world)
        world.removeComponent(type: SpriteComponent.self, from: renderableEntity)
        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.removeCalls.contains(renderableEntity))
    }

    func testDestroyedEntityGetsRemoveNodeCalledNextFrame() {
        system.update(deltaTime: 0.016, world: world)
        world.destroyEntity(entity: renderableEntity)
        system.update(deltaTime: 0.016, world: world)

        XCTAssertTrue(backend.removeCalls.contains(renderableEntity))
    }

    func testRemoveNodeNotCalledForEntityStillRenderable() {
        system.update(deltaTime: 0.016, world: world)
        system.update(deltaTime: 0.016, world: world)

        XCTAssertFalse(backend.removeCalls.contains(renderableEntity))
    }

    // MARK: - Health visibility

    func testNonPlayerEntityHealthIsPassedToBackend() {
        system.update(deltaTime: 0.016, world: world)

        let call = backend.syncCalls.first { $0.entity == enemyEntity }
        XCTAssertNotNil(call?.health)
    }

    func testPlayerEntityHealthIsNotPassedToBackend() {
        system.update(deltaTime: 0.016, world: world)

        let call = backend.syncCalls.first { $0.entity == playerEntity }
        XCTAssertNil(call?.health)
    }

    // MARK: - Directional animation flag

    func testEntityWithAnimationComponentSetsDirectionalAnimationFlag() {
        system.update(deltaTime: 0.016, world: world)

        let call = backend.syncCalls.first { $0.entity == animatedEntity }
        XCTAssertTrue(call?.hasDirectionalAnimation == true)
    }

    func testEntityWithoutAnimationComponentDoesNotSetDirectionalAnimationFlag() {
        system.update(deltaTime: 0.016, world: world)

        let call = backend.syncCalls.first { $0.entity == renderableEntity }
        XCTAssertTrue(call?.hasDirectionalAnimation == false)
    }
}
