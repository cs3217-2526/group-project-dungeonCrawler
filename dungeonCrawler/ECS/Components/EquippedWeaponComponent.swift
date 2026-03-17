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

struct EquippedWeaponComponent: Component {
    var primaryWeapon: Entity
    var secondaryWeapon: Entity?
}