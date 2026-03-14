# ECS

## Component

Component is just a marker protocol — it tags a type as eligible to be stored in the ECS.

`Component<T>` is a per-component-type storage. It holds a dictionary of Entity -> T for one specific component type (like Position or Velocity).
```swift
private var _data: [Entity: T] = [:]
```

`ComponentStorage` is the top-level registry. It keeps many `ComponentStore<T>` instances, one per component type, in a dictionary keyed by the component’s runtime type (ObjectIdentifier). It exposes add/get/remove/modify APIs and the subscript sugar. See
```swift
private var _stores: [ObjectIdentifier: any AnyComponentStore] = [:]
```