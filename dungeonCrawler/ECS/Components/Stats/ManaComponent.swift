import Foundation

public struct ManaComponent: StatProvidable {
    public var value: StatValue
    public var regenRate: Float

    public init(base: Float, max: Float, regenRate: Float = 0) {
        self.value = StatValue(base: base, max: max)
        self.regenRate = regenRate
    }
}
