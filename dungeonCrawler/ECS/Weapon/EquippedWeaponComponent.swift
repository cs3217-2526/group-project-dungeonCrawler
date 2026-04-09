/**
 * A component that stores the equipped weapons of an entity.
 * 
 * A player can have 2 weapons and must have a primary weapon.
 * 
 * Future additions:
 *   - Add a way to switch between weapons
 *   - Add a way to drop weapons
 *   - Add a way to pick up weapons
 */

class EquippedWeaponComponent: Component {
//    public init(capacity: Int) {
//        if capacity > 1 {
//            weapons = []
//        }
//    }
//    var currentWeapon: Entity
//    var weapons: [Entity?]
    var primaryWeapon: Entity
    var secondaryWeapon: Entity?
    
    public init(primaryWeapon: Entity, secondaryWeapon: Entity? = nil) {
        self.primaryWeapon = primaryWeapon
        self.secondaryWeapon = secondaryWeapon
    }
    
}
