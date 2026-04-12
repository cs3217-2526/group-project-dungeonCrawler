class ProjectileComponent: Component {
    var hitEffects: [any ProjectileHitEffect] = []
    
    init(hitEffects: [any ProjectileHitEffect]) {
        self.hitEffects = hitEffects
    }
}
