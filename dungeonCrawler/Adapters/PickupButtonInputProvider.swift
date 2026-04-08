//
//  PickupWeaponButtonInputProvider.swift
//  dungeonCrawler
//
//  Created by Letian on 4/4/26.
//

import Foundation
import UIKit

public final class PickupButtonInputProvider {
    public let button: UIButton
    private let commandQueues: CommandQueues
    public init(commandQueues: CommandQueues) {
        self.commandQueues = commandQueues
        
        let btn = CircleButton(type: .system)
        btn.setTitle("Pickup", for: .normal)
        btn.backgroundColor = UIColor(white: 1, alpha: 0.2)
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        self.button = btn
        btn.addTarget(self, action: #selector(buttonDown), for: .touchDown)
    }

    @objc private func buttonDown() {
        commandQueues.push(PickupCommand(id: CommandId()))
    }
}
