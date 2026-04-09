import Foundation

public class EffectiveRangeComponent: StatProvidable {
    public var value: StatValue

    public init(base: Float) {
        self.value = StatValue(base: base)
    }
}
