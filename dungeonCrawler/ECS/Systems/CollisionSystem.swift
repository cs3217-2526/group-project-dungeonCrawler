//
//  CollisionSystem.swift
//  dungeonCrawler
//
//  Created by Yu Letian on 16/3/26.
//

public final class CollisionSystem: System {
    public let priority: Int = 10

    public func update(deltaTime: Double, world: World) {
        // OBB collision detection and resolution using SAT (Separating Axis Theorem).

    }

    /// Returns true if the two OBBs overlap.
    public func checkCollision(
        transformA: TransformComponent, boxA: CollisionBoxComponent,
        transformB: TransformComponent, boxB: CollisionBoxComponent
    ) -> Bool {
        minimumTranslationVector(transformA: transformA, boxA: boxA,
                                  transformB: transformB, boxB: boxB) != nil
    }

    /// Returns the MTV that separates A from B, or nil if they do not overlap.
    private func minimumTranslationVector(
        transformA: TransformComponent, boxA: CollisionBoxComponent,
        transformB: TransformComponent, boxB: CollisionBoxComponent
    ) -> SIMD2<Float>? {
        nil // TODO: implement SAT
    }
}
