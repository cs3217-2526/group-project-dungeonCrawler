//
//  CommandQueues.swift
//  dungeonCrawler
//
//  Created by Letian on 27/3/26.
//

import Foundation

// we make it referenced
// since systems need to borrow the queues
public class CommandQueues {
    private var queues: [ObjectIdentifier: AnyObject] = [:]

    func queue<C: Command>(for type: C.Type) -> CommandQueue<C>? {
        queues[ObjectIdentifier(type)] as? CommandQueue<C>
    }

    func register<C: Command>(_ type: C.Type, capacity: Int = 32) {
        queues[ObjectIdentifier(type)] = CommandQueue<C>(capacity: capacity)
    }

    func push<C: Command>(_ command: C) {
        queue(for: C.self)?.enqueue(command)
    }

    func pop<C: Command>(_ type: C.Type) -> C? {
        queue(for: type)?.dequeue()
    }

    func cancelAcrossAll(commandId: CommandId) {
        queues.values.forEach { queue in
            (queue as? Cancellable)?.cancel(commandId: commandId)
        }
    }
}
