//
//  MassComponent.swift
//  dungeonCrawler
//
//  Created by Wen Kang Yap on 24/3/26.
//

public class MassComponent: Component {
    public var mass: Int

    // Player will make use of the default mass 10
    public init(mass: Int = 10) {
        self.mass = mass
    }
}
