import Foundation
import simd

typealias WeaponConfig = [String: WeaponValue]

enum WeaponValue {
    case int(Int)
    case float(Float)
    case string(String)
    case bool(Bool)
    case vector2(SIMD2<Float>)
    case array([WeaponValue])
    case object([String: WeaponValue])
}

struct WeaponDefinition {
    // general fields
    let id: String
    let textureName: String
    let offset: SIMD2<Float>
    let scale: Float
    let cooldown: TimeInterval?
    let attackSpeed: Float?
    let anchorPoint: SIMD2<Float>?
    let initRotation: Float?
    let tags: Set<String>
    // extensible
    let config: WeaponConfig
}

/// What default value user want can tailor config
extension WeaponDefinition {
    func float(_ key: String) -> Float? {
        guard case let .float(value)? = config[key] else { return nil }
        return value
    }

    func int(_ key: String) -> Int? {
        guard case let .int(value)? = config[key] else { return nil }
        return value
    }

    func string(_ key: String) -> String? {
        guard case let .string(value)? = config[key] else { return nil }
        return value
    }

    func vector2(_ key: String) -> SIMD2<Float>? {
        guard case let .vector2(value)? = config[key] else { return nil }
        return value
    }

    func hasTag(_ tag: String) -> Bool {
        tags.contains(tag)
    }
}

enum WeaponLibrary {
    private static let definitions: [String: WeaponDefinition] = [
        "handgun": WeaponDefinition(
            id: "handgun",
            textureName: "handgun",
            offset: SIMD2<Float>(10, -5),
            scale: WorldConstants.standardEntityScale,
            cooldown: 0.2,
            attackSpeed: 1,
            anchorPoint: nil,
            initRotation: nil,
            tags: ["projectile", "usesMana"],
            config: [
                "manaCost": .float(5),
                "projectileSpeed": .float(300),
                "effectiveRange": .float(400),
                "damage": .float(15),
                "projectileSpriteName": .string("normalHandgunBullet"),
                "collisionSize": .vector2(SIMD2<Float>(6, 6))
            ]
        ),
        "sword": WeaponDefinition(
            id: "sword",
            textureName: "sword",
            offset: SIMD2<Float>(12, -6),
            scale: 0.3,
            cooldown: 0.5,
            attackSpeed: 1,
            anchorPoint: SIMD2<Float>(0.1, 0.5),
            initRotation: .pi / 9,
            tags: ["melee"],
            config: [
                "damage": .float(50),
                "range": .float(100),
                "halfAngleDegrees": .float(90),
                "maxTargets": .int(1),
                "swingDuration": .float(0.3),
                "swingAngleDegrees": .float(40)
            ]
        ),
        "sniper": WeaponDefinition(
            id: "sniper",
            textureName: "Sniper",
            offset: SIMD2<Float>(10, -5),
            scale: WorldConstants.standardEntityScale,
            cooldown: TimeInterval(0.8),
            attackSpeed: 1,
            anchorPoint: nil,
            initRotation: nil,
            tags: ["projectile", "usesMana"],
            config: [
                "manaCost": .float(20),
                "projectileSpeed": .float(400),
                "effectiveRange": .float(800),
                "damage": .float(50),
                "projectileSpriteName": .string("normalHandgunBullet"),
                "collisionSize": .vector2(SIMD2<Float>(6, 6))
            ]
        )
    ]

    static func definition(for id: String) -> WeaponDefinition? {
        definitions[id]
    }
}
