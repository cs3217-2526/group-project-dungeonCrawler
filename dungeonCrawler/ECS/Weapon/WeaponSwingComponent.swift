import Foundation

public struct WeaponSwingComponent: Component {
    var elapsed: Float
    var duration: Float
    var baseRotation: Float
    var amplitude: Float
    var directionSign: Float

    init(
        elapsed: Float = 0,
        duration: Float,
        baseRotation: Float,
        amplitude: Float,
        directionSign: Float
    ) {
        self.elapsed = elapsed
        self.duration = duration
        self.baseRotation = baseRotation
        self.amplitude = amplitude
        self.directionSign = directionSign
    }
}
