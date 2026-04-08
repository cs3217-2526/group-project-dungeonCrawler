//
//  DropAndPickedWeaponButtonInputProvider.swift
//  dungeonCrawler
//
//  Created by Letian on 4/4/26.
//

import Foundation
import UIKit

public final class DropWeaponButtonInputProvider {
    public let button: UIButton
    private let commandQueues: CommandQueues
    public init(commandQueues: CommandQueues) {
        self.commandQueues = commandQueues
        
        let btn = CircleButton(type: .system)
        btn.setTitle("Drop", for: .normal)
        btn.backgroundColor = UIColor(white: 1, alpha: 0.2)
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        self.button = btn
        btn.addTarget(self, action: #selector(buttonDown), for: .touchDown)
    }

    @objc private func buttonDown() {
        commandQueues.push(DropWeaponCommand(id: CommandId()))
    }
}
