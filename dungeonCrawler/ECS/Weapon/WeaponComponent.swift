import Foundation

struct WeaponComponent: Component {
    var type: WeaponType
    var manaCost: Float
    var attackSpeed: Float
    var coolDownInterval: TimeInterval
    var lastFiredAt: Float = 0

    init(type: WeaponType,
         manaCost: Float,
         attackSpeed: Float,
         coolDownInterval: TimeInterval,
         lastFiredAt: Float) {
        self.type = type
        self.manaCost = manaCost
        self.attackSpeed = attackSpeed
        self.coolDownInterval = coolDownInterval
        self.lastFiredAt = lastFiredAt
    }
}

public enum WeaponType: String {
    case handgun
    case sword
    case bow
    case sniper

    var textureName: String {
        switch self {
        case .handgun: return "handgun"
        case .sniper: return "Sniper"
        case .sword: return "sword"
        case .bow: return "bow"
        }
    }
}
