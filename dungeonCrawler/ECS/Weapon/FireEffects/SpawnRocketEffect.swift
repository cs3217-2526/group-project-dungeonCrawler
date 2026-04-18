import Foundation
import simd

struct SpawnRocketEffect: WeaponEffect {
    let speed: Float
    let damage: Float
    let spriteName: String
    let collisionSize: SIMD2<Float>
    let gravity: Float
    let launchAngle: Float

    init(
        speed: Float,
        damage: Float,
        spriteName: String,
        collisionSize: SIMD2<Float>,
        gravity: Float = 300,
        launchAngle: Float = 0
    ) {
        self.speed = speed
        self.gravity = gravity
        self.launchAngle = launchAngle
        self.damage = damage
        self.spriteName = spriteName
        self.collisionSize = collisionSize
    }

    func apply(context: FireContext) -> FireEffectResult {
        let dir = simd_normalize(context.fireDirection)
        // Rotate the direction upward by launchAngle to create the initial arc
        let cosA = cos(launchAngle)
        let sinA = sin(launchAngle)
        let loftedDir = SIMD2<Float>(
            dir.x * cosA - dir.y * sinA,
            dir.x * sinA + dir.y * cosA
        )
        let fireAngle = atan2(loftedDir.y, loftedDir.x)
        guard (.pi / 20 ... .pi * 19/20).contains(fireAngle) else {
            return .blocked("fire down not allowed")
        }
        let vx0 = Double(abs(speed * cos(fireAngle)))
        let vz0 = Double(speed * sin(fireAngle))
        let g = Double(gravity)
        let effectiveRange = Float(
            (vz0 * Double(speed) + vx0 * vx0 * asinh(vz0 / vx0)) / g
        )

        let entity = ProjectileEntityFactory(
            from: context.firePosition,
            aimAt: loftedDir,
            speed: speed,
            effectiveRange: effectiveRange,
            damage: damage,
            owner: context.owner,
            spriteName: spriteName,
            collisionBoxSize: collisionSize,
            hitEffects: [SpawnZoneEffect()]
        ).make(in: context.world)

        context.world.addComponent(
            component: GravityComponent(gravity: gravity),
            to: entity
        )

        return .success
    }
}
