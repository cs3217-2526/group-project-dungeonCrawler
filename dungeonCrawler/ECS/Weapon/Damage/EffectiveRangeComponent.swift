import Foundation

public struct EffectiveRangeComponent: StatProvidable {
    public var value: StatValue

    public init(base: Float) {
        self.value = StatValue(base: base)
    }
}
