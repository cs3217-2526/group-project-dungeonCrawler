//
//  ReloadButton.swift
//  dungeonCrawler
//
//  Created by Letian on 28/3/26.
//

import Foundation
import UIKit

private final class CircleButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}

public final class SwitchWeaponButtonInputProvider {

    /// The button to add to the game view's UI layer.
    public let button: UIButton

    private let commandQueues: CommandQueues

    public init(commandQueues: CommandQueues) {
        self.commandQueues = commandQueues

        let btn = CircleButton(type: .system)
        btn.setTitle("Switch", for: .normal)
        btn.backgroundColor = UIColor(white: 1, alpha: 0.2)
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        self.button = btn

        btn.addTarget(self, action: #selector(buttonDown), for: .touchDown)
    }

    @objc private func buttonDown() {
        commandQueues.push(SwitchWeaponCommand(id: UUID()))
    }
}
