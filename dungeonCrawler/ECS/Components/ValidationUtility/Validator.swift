class Validator {
    static func validate<T: Component>(component: T, in world: World) {
        if component is SingletonComponent {
            guard world.entities(with: T.self).isEmpty else {
                fatalError("\(T.self) is a singleton but already exists on another entity.")
            }
        }
    }
}