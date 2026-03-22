//
//  InputSystem.swift
//  dungeonCrawler
//
//  Created by Jannice Suciptono on 11/3/26.
//

import Foundation
import simd

// MARK: - InputProvider protocol

/// Abstracts the source of raw input so the system is hardware-agnostic.
public protocol InputProvider: AnyObject {
    var rawMoveVector: SIMD2<Float> { get }

    var rawAimVector: SIMD2<Float> { get }

    var isShootPressed: Bool { get }
}

// MARK: - InputSystem

public final class InputSystem: System {

    public let priority: Int = 10

    private weak var inputProvider: InputProvider?

    public init(inputProvider: InputProvider) {
        self.inputProvider = inputProvider
    }

    public func update(deltaTime: Double, world: World) {
        guard let provider = inputProvider else { return }

        let moveDirection = provider.rawMoveVector
        let aimDirection  = provider.rawAimVector
        let shooting      = provider.isShootPressed

        for entity in world.entities(with: InputComponent.self) {
            guard world.getComponent(type: KnockbackComponent.self, for: entity) == nil else { continue }

            world.modifyComponent(type: InputComponent.self, for: entity) { input in
                input.moveDirection = moveDirection
                input.aimDirection  = aimDirection
                input.isShooting    = shooting
            }

            // Update facing: aim direction takes priority over move direction when aim input is present.
            let facingX: Float = aimDirection.x != 0 ? aimDirection.x : moveDirection.x
            guard facingX != 0 else { continue }
            world.modifyComponent(type: FacingComponent.self, for: entity) { facing in
                facing.facing = facingX > 0 ? .right : .left
            }
        }
    }
}
