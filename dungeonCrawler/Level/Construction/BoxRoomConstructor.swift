import Foundation
import simd

/// Constructs an axis-aligned room using a `RoomBuilder`.
///
/// Walls are built around the perimeter and split for `doorways`.
/// Obstacles are scattered purely via procedural logic.
public final class BoxRoomConstructor: RoomConstructor {

    public struct Config {
        /// Inset from walls where obstacles cannot spawn.
        public var wallMargin: Float = 48
        /// Clear radius at center for start/player positioning.
        public var centerClearRadius: Float = 100
        /// Density coefficient for obstacles.
        public var obstacleDensity: Float = 0.12
        /// Whether to create visual sprites (Floor/Wall) in addition to colliders.
        public var renderVisualSprites: Bool = true

        public init() {}
    }

    private let config: Config

    public init(config: Config = Config()) {
        self.config = config
    }

    public func construct(
        builder: RoomBuilder,
        specification: RoomSpecification,
        doorways: [Doorway],
        using generator: inout SeededGenerator
    ) {
        let bounds = specification.bounds
        
        // If config explicitly disables visuals, override the builder setting.
        if !config.renderVisualSprites {
            builder.renderVisualSprites = false
        }

        builder.addFloor()
        createPerimeterWalls(bounds: bounds, doorways: doorways, builder: builder)
        // createObstacles(bounds: bounds, builder: builder, using: &generator)
    }

    // MARK: - Perimeter Walls

    private func createPerimeterWalls(
        bounds: RoomBounds,
        doorways: [Doorway],
        builder: RoomBuilder
    ) {
        let t = WorldConstants.wallThickness

        createHorizontalWall(
            y: bounds.minY + t / 2,
            bounds: bounds, facing: .south, doorways: doorways,
            builder: builder
        )
        createHorizontalWall(
            y: bounds.maxY - t / 2 - 2 * t,
            bounds: bounds, facing: .north, doorways: doorways,
            builder: builder
        )
        createVerticalWall(
            x: bounds.minX + t / 2,
            bounds: bounds, facing: .west, doorways: doorways,
            builder: builder
        )
        createVerticalWall(
            x: bounds.maxX - t / 2,
            bounds: bounds, facing: .east, doorways: doorways,
            builder: builder
        )
    }

    private func createHorizontalWall(
        y: Float,
        bounds: RoomBounds,
        facing: Direction,
        doorways: [Doorway],
        builder: RoomBuilder
    ) {
        let t = WorldConstants.wallThickness
        let openings = doorways.filter { $0.direction == facing }
        let xStart = bounds.minX + t
        let xEnd   = bounds.maxX   - t

        if openings.isEmpty {
            let w = xEnd - xStart
            builder.addWall(at: SIMD2((xStart + xEnd) / 2, y), size: SIMD2(w, t))
            return
        }

        let sorted = openings.sorted { $0.position.x < $1.position.x }
        var cursor = xStart

        for opening in sorted {
            let half = opening.width / 2
            let gapFrom = opening.position.x - half
            let gapTo   = opening.position.x + half
            if gapFrom > cursor {
                let w = gapFrom - cursor
                builder.addWall(at: SIMD2(cursor + w / 2, y), size: SIMD2(w, t))
            }
            cursor = gapTo
        }
        if cursor < xEnd {
            let w = xEnd - cursor
            builder.addWall(at: SIMD2(cursor + w / 2, y), size: SIMD2(w, t))
        }
    }

    private func createVerticalWall(
        x: Float,
        bounds: RoomBounds,
        facing: Direction,
        doorways: [Doorway],
        builder: RoomBuilder
    ) {
        let t = WorldConstants.wallThickness
        let openings = doorways.filter { $0.direction == facing }
        let yStart = bounds.minY
        let yEnd   = bounds.maxY

        if openings.isEmpty {
            let h = yEnd - yStart
            builder.addWall(at: SIMD2(x, (yStart + yEnd) / 2), size: SIMD2(t, h))
            return
        }

        let sorted = openings.sorted { $0.position.y < $1.position.y }
        var cursor = yStart
        for opening in sorted {
            let half = opening.width / 2
            let gapFrom = opening.position.y - half
            let gapTo   = opening.position.y + half
            if gapFrom > cursor {
                let h = gapFrom - cursor
                builder.addWall(at: SIMD2(x, cursor + h / 2), size: SIMD2(t, h))
            }
            cursor = gapTo
        }
        if cursor < yEnd {
            let h = yEnd - cursor
            builder.addWall(at: SIMD2(x, cursor + h / 2), size: SIMD2(t, h))
        }
    }

    // MARK: - Obstacles

    private func createObstacles(bounds: RoomBounds, builder: RoomBuilder, using generator: inout SeededGenerator) {
        let margin = config.wallMargin
        let safeArea = bounds.inset(by: margin)

        guard safeArea.size.x > 0, safeArea.size.y > 0 else { return }

        let area = safeArea.size.x * safeArea.size.y
        let maxObstacles = Int(area / 5_000 * config.obstacleDensity)
        var placed = 0
        var attempts = 0

        while placed < maxObstacles && attempts < maxObstacles * 10 {
            attempts += 1
            let pos = safeArea.randomPosition(margin: 0, using: &generator)
            if simd_distance(pos, bounds.center) < config.centerClearRadius { continue }

            let size = SIMD2<Float>(
                Float.random(in: 24...48, using: &generator),
                Float.random(in: 24...48, using: &generator)
            )
            builder.addObstacle(at: pos, size: size)
            placed += 1
        }
    }
}
