import Foundation

/// ObjC-compatible bridge for ``SplashScreen``.
///
/// `SplashScreen` inherits from `HybridSplashScreenSpec` (a C++ class),
/// so it cannot be referenced directly from the ObjC runtime.
/// This thin `NSObject` subclass exposes the static API to ObjC callers
/// (e.g. the `+load` auto-show in `SplashScreenBridge.mm`).
@objc public class SplashScreenBridge: NSObject {
    @objc public static func show()     { SplashScreen.showSplash() }
    @objc public static func hide()     { SplashScreen.hideSplash() }
    @objc public static func autoShow() { SplashScreen.autoShow() }

    /// Configure the Lottie animation file name (without extension).
    /// Call before the splash is shown (e.g. in AppDelegate, before super.init).
    @objc public static func setAnimationName(_ name: String) {
        SplashScreen.setAnimationName(name)
    }
}
