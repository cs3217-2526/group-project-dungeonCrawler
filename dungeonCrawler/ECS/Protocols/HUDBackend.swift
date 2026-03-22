import Foundation

/// Engine-agnostic interface used by HUDSystem to push stat values to the visual overlay.
public protocol HUDBackend: AnyObject {
    func updateHealthBar(current: Float, max: Float)
    func updateManaBar(current: Float, max: Float)
}
