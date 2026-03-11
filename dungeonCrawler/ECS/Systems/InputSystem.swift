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

        let rawMove = provider.rawMoveVector
        let moveLen = length(rawMove)
        let normalisedMove: SIMD2<Float> = moveLen > 0.001 ? rawMove / moveLen : .zero

        let rawAim = provider.rawAimVector
        let aimLen = length(rawAim)
        let normalisedAim: SIMD2<Float> = aimLen > 0.001 ? rawAim / aimLen : .zero

        for entity in world.entities(with: InputComponent.self) {
            guard let input = world.getComponent(type: InputComponent.self, for: entity)
            else { continue }

            input.moveDirection = normalisedMove
            input.aimDirection  = normalisedAim
            input.isShooting    = provider.isShootPressed
        }
    }
}
