---
title: "Command"
description: "The Command protocol and how commands are structured."
sidebar_position: 1
---

## CommandQueues

`CommandQueues` is a referenced type container that stores queues of different command types. Usually one game should only have one `CommandQueues` instance, which is passed to any system that needs to produce or consume commands.

## CommandQueue

`CommandQueue` is a generic container that stores a queue of commands of a specific type.

### How to add a new command

1. create a struct that conforms to `Command`.
2. create a producer that construct the command and add it to the `commandQueues` via `commandQueues.push(NewCommand(id: CommandId()))`
3. register that commandQueue into the `CommandQueues` instance, e.g. `commandQueues.register(NewCommand.self)`
4. update the consume logic in `InputSystem` to consume the command, e.g. 
   
   ```swift
    while commandQueues.pop(NewCommand.self) != nil {
        // Consume the command
    }
   ```
