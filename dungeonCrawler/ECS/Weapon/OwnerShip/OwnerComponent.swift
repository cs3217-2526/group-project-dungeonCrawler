import Foundation
import simd

public class OwnerComponent: Component {
    var ownerEntity: Entity

    var offset: SIMD2<Float>

    init(ownerEntity: Entity, offset: SIMD2<Float> = .zero) {
        self.ownerEntity = ownerEntity
        self.offset = offset
    }
}
