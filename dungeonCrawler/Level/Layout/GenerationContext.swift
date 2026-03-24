import Foundation

/// Encapsulates parameters for a dungeon generation pass.
public struct GenerationContext {
    /// The 1-based index of the dungeon floor (Progression).
    public let floorIndex: Int
    
    /// A value from 1.0 (Normal) upward to scale challenge (Difficulty).
    public let difficultyMultiplier: Float
    
    /// A seed for deterministic randomization (Repeatability).
    public let seed: UInt64

    public init(
        floorIndex: Int,
        difficultyMultiplier: Float = 1.0,
        seed: UInt64 = UInt64.random(in: 0...UInt64.max)
    ) {
        self.floorIndex = floorIndex
        self.difficultyMultiplier = difficultyMultiplier
        self.seed = seed
    }

    /// Creates a fresh generator using the context's seed.
    public func makeGenerator() -> SeededGenerator {
        return SeededGenerator(seed: seed)
    }
}
