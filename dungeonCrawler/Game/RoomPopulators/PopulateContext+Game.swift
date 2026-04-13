import Foundation
import simd

/// Game-specific extensions for `PopulateContext`.
///
/// These helpers allow room populators to spawn gameplay entities while
/// maintaining the modular boundary between level generation and game logic.
extension PopulateContext {
    
    /// Spawns an enemy and automatically attaches a `RoomMemberComponent`.
    @discardableResult
    public mutating func spawnEnemy(at position: SIMD2<Float>, type: EnemyType) -> Entity {
        let enemy = EnemyEntityFactory(
            at: position,
            type: type,
            baseScale: scale
        ).make(in: world)
        world.addComponent(
            component: RoomMemberComponent(roomID: roomID),
            to: enemy
        )
        
        // Register this position as occupied
        occupiedPositions.append(position)
        
        return enemy
    }

    /// Spawns weapons and automatically attaches a `RoomMemberComponent`.
    @discardableResult
    public mutating func spawnWeapon(at position: SIMD2<Float>) -> Entity {
        let sniperDefinition = WeaponType.sniper.baseDefinition
        let weapon = WeaponEntityFactory(base: sniperDefinition).make(in: world, initLocation: position)
        world.addComponent(
            component: SpriteComponent(
                content: .texture(name: sniperDefinition.textureName),
                layer: .weaponFront,
                anchorPoint: sniperDefinition.anchorPoint ?? SIMD2<Float>(0.5, 0.5)),
            to: weapon)
        world.addComponent(
            component: RoomMemberComponent(roomID: roomID),
            to: weapon
        )
        occupiedPositions.append(position)

        // Also spawn a bazooka nearby
        if let bazookaPos = findEmptySpace() {
            let bazookaDef = WeaponType.bazooka.baseDefinition
            let bazookaWeapon = WeaponEntityFactory(base: bazookaDef).make(in: world, initLocation: bazookaPos)
            world.addComponent(
                component: SpriteComponent(
                    content: .texture(name: bazookaDef.textureName),
                    layer: .weaponFront,
                    anchorPoint: bazookaDef.anchorPoint ?? SIMD2<Float>(0.5, 0.5)),
                to: bazookaWeapon)
            world.addComponent(
                component: RoomMemberComponent(roomID: roomID),
                to: bazookaWeapon
            )
            occupiedPositions.append(bazookaPos)
        }

        return weapon
    }
}
