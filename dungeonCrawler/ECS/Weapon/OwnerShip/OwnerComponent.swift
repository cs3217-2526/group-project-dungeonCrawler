import Foundation
import simd

public class OwnerComponent: Component {
    var ownerEntity: Entity

    init(ownerEntity: Entity) {
        self.ownerEntity = ownerEntity
    }
}
