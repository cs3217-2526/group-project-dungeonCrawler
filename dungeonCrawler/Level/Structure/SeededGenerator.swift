import Foundation

/// A deterministic pseudo-random number generator using the Linear Congruential 
/// Generator (LCG) algorithm. 
/// 
/// Conforms to Swift’s `RandomNumberGenerator` protocol, allowing it to 
/// be used with all standard `random(in:using:)` methods.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        // Ensure the seed is never zero to avoid a stuck state
        self.state = seed == 0 ? 0xDECAFBAD : seed
    }

    /// Generates the next 64-bit random value.
    /// Uses the 64-bit LCO algorithm constants from Numerical Recipes.
    public mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}
