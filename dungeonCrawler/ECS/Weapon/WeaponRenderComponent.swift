//
//  WeaponRenderComponent.swift
//  dungeonCrawler
//
//  Created by Letian on 31/3/26.
//

import Foundation
import simd

public class WeaponRenderComponent: Component {
    let textureName: String
    let anchorPoint: SIMD2<Float>
    let initRotation: Float
    
    public init(textureName: String, anchorPoint: SIMD2<Float>, initRotation: Float) {
        self.textureName = textureName
        self.anchorPoint = anchorPoint
        self.initRotation = initRotation
    }
}
