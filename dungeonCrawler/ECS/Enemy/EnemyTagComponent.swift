//
//  EnemyTagComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 16/3/26.
//

import Foundation

public class EnemyTagComponent: Component {
    public let textureName: String
    public let scale: Float

    public init(textureName: String, scale: Float) {
        self.textureName = textureName
        self.scale = scale
    }
}
