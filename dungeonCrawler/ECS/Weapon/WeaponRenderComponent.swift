//
//  WeaponRenderComponent.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation
import simd

public struct WeaponRenderComponent: Component {
    let textureName: String
    let anchorPoint: SIMD2<Float>
    let initRotation: Float
}
