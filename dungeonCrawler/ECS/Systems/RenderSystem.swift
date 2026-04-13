//
//  RenderSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation

public final class RenderSystem: System {

    public var dependencies: [System.Type] { [CameraSystem.self, HUDSystem.self, ProjectileSystem.self, AnimationSystem.self] }

    private weak var backend: RenderingBackend?
    private var seenEntities: Set<Entity> = []

    public init(backend: RenderingBackend) {
        self.backend = backend
    }

    // MARK: - Update

    public func update(deltaTime: Double, world: World) {
        guard let backend else { return }

        let renderables = world.entities(
            with: TransformComponent.self,
            and: SpriteComponent.self
        )

        var currentEntities = Set<Entity>()

        for (entity, transform, sprite) in renderables {
            currentEntities.insert(entity)
            let facing   = world.getComponent(type: FacingComponent.self, for: entity)
            let velocity = world.getComponent(type: VelocityComponent.self, for: entity)

            let isPlayer = world.getComponent(type: PlayerTagComponent.self, for: entity) != nil
            let health   = !isPlayer ? world.getComponent(type: HealthComponent.self, for: entity) : nil

            backend.syncNode(for: entity, transform: transform, sprite: sprite,
                             facing: facing, velocity: velocity, health: health)
        }

        // Remove nodes for entities that no longer have both components.
        let staleEntities = seenEntities.subtracting(currentEntities)
        for entity in staleEntities {
            backend.removeNode(for: entity)
        }
        seenEntities = currentEntities
    }
}
