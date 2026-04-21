//
//  EnemyType.swift
//  dungeonCrawler
//

import Foundation

// To add a new enemy type, add a single static let block below
public struct EnemyType {
    public let textureName: String
    public let scale: Float
    public let mass: Int
    public let contactDamage: Float
    public let strategy: any EnemyStrategy

    public static let charger = EnemyType(
        textureName: "Charger",
        scale: 1.0,
        mass: 15,
        contactDamage: 20.0,
        strategy: StandardStrategy()
    )

    public static let mummy = EnemyType(
        textureName: "Mummy",
        scale: 1.0,
        mass: 10,
        contactDamage: 10.0,
        strategy: TimidStrategy()
    )

    public static let ranger = EnemyType(
        textureName: "Ranger",
        scale: 0.75,
        mass: 5,
        contactDamage: 5.0,
        strategy: StandardStrategy(
            wanderBehaviour: WanderBehaviour(),
            attackBehaviour: CompositeBehaviour(
                OrbitBehaviour(),
                ShooterBehaviour(
                    weaponBase: WeaponType.enemyRangedDefault.baseDefinition)
            )
        )
    )

    public static let tower = EnemyType(
        textureName: "Tower",
        scale: 1.5,
        mass: 20,
        contactDamage: 15.0,
        strategy: StandardStrategy(
            detectionRadius: 300,
            wanderBehaviour: StationaryBehaviour(),
            attackBehaviour: CompositeBehaviour(
                StationaryBehaviour(),
                ShooterBehaviour(weaponBase: WeaponType.towerAttack.baseDefinition)
            )
        )
    )
}
