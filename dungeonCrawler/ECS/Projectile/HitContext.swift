//
//  HitContext.swift
//  dungeonCrawler
//
//  Created by Letian on 12/4/26.
//

import Foundation
import simd
 
/// Passed to every ProjectileHitEffect when a projectile resolves.
///
/// - center:   world position of the impact.
/// - world:    ECS world reference.
/// - target:   the specific Entity that was hit, or nil for wall/range-expiry hits.
/// - zoneBase: only populated when an effect that needs zone data carries it in
///             (see SpawnZoneEffect). Most effects leave this nil.
public struct HitContext {
    public let center: SIMD2<Float>
    public let world: World
    public let target: Entity?
    public let zoneBase: ZoneBase?
}
 
