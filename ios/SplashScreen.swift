import UIKit
#if LOTTIE_INSTALLED
import Lottie
#endif
import NitroModules

/// A splash screen module for React Native using NitroModules.
///
/// Displays a splash screen in a dedicated UIWindow above all other content.
///
/// - **With Lottie**: If `lottie-react-native` is installed and a JSON file
///   matching ``animationName`` exists in the main bundle, a full-screen Lottie
///   animation is shown directly (no storyboard flash).
/// - **Without Lottie**: Falls back to `LaunchScreen.storyboard`.
class SplashScreen: HybridSplashScreenSpec {

    // MARK: - State

    private static var splashWindow: UIWindow?
    #if LOTTIE_INSTALLED
    private static var lottieView: LottieAnimationView?
    #endif
    private static var isVisible = false
    private static var sceneObserver: NSObjectProtocol?
    private static var jsErrorObserver: NSObjectProtocol?

    // MARK: - Configuration

    /// The Lottie JSON file name (without extension).
    /// Resolved in order:
    /// 1. Value set via `setAnimationName(_:)` / `SplashScreenBridge.setAnimationName(_:)`
    /// 2. `SplashScreenAnimationName` key in Info.plist
    /// 3. Default: `"splash_screen"`
    private(set) static var animationName: String = {
        if let name = Bundle.main.object(forInfoDictionaryKey: "SplashScreenAnimationName") as? String,
           !name.isEmpty {
            return name
        }
        return "splash_screen"
    }()

    static func setAnimationName(_ name: String) {
        animationName = name
    }

    // MARK: - HybridObject interface

    func show() throws { SplashScreen.showSplash() }
    func hide() throws { SplashScreen.hideSplash() }

    // MARK: - Public API

    static func autoShow() {
        NSLog("[SplashScreen] autoShow() called")
        if let scene = activeWindowScene {
            NSLog("[SplashScreen] Scene already available, showing immediately")
            showWithScene(scene)
            return
        }

        NSLog("[SplashScreen] No scene yet, waiting for willConnectNotification")
        sceneObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willConnectNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let scene = notification.object as? UIWindowScene else { return }
            showWithScene(scene)
            removeSceneObserver()
        }
    }

    static func showSplash() {
        onMainThread { showOnMainThread() }
    }

    static func hideSplash() {
        onMainThread { hideOnMainThread() }
    }

    // MARK: - Internals

    private static func showWithScene(_ scene: UIWindowScene) {
        guard !isVisible else { return }
        NSLog("[SplashScreen] showWithScene called")

        let vc = makeSplashViewController()
        NSLog("[SplashScreen] VC type: %@", String(describing: type(of: vc)))

        let window = UIWindow(windowScene: scene)
        window.rootViewController = vc
        window.windowLevel = .statusBar + 1
        window.makeKeyAndVisible()

        splashWindow = window
        isVisible = true
        observeJSLoadError()
    }

    private static func showOnMainThread() {
        guard !isVisible, let scene = activeWindowScene else { return }
        showWithScene(scene)
    }

    private static func hideOnMainThread() {
        guard isVisible, let window = splashWindow else { return }

        #if LOTTIE_INSTALLED
        lottieView?.stop()
        #endif

        UIView.animate(withDuration: 0.25, animations: {
            window.alpha = 0
        }, completion: { _ in
            window.isHidden = true
            #if LOTTIE_INSTALLED
            lottieView?.removeFromSuperview()
            lottieView = nil
            #endif
            splashWindow = nil
            isVisible = false
            removeJSErrorObserver()
        })
    }

    // MARK: - View Controller Factory

    /// Creates the splash view controller:
    /// 1. If Lottie JSON is available → dedicated VC with LottieAnimationView as root view (no storyboard)
    /// 2. Otherwise → LaunchScreen.storyboard VC
    private static func makeSplashViewController() -> UIViewController {
        #if LOTTIE_INSTALLED
        NSLog("[SplashScreen] LOTTIE_INSTALLED = true")
        if let vc = makeLottieViewController() {
            NSLog("[SplashScreen] Using Lottie VC")
            return vc
        }
        NSLog("[SplashScreen] Lottie VC creation failed, falling back to storyboard")
        #else
        NSLog("[SplashScreen] LOTTIE_INSTALLED = false")
        #endif

        // Fallback: storyboard
        if let vc = UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController() {
            NSLog("[SplashScreen] Using storyboard VC")
            return vc
        }

        // Last resort: blank white VC
        return UIViewController()
    }

    #if LOTTIE_INSTALLED
    /// Creates a VC whose entire view IS the Lottie animation — no storyboard involved.
    /// Returns nil if the JSON file is not found or cannot be parsed.
    private static func makeLottieViewController() -> UIViewController? {
        NSLog("[SplashScreen] Looking for '%@.json' in main bundle", animationName)
        guard let path = Bundle.main.path(forResource: animationName, ofType: "json") else {
            NSLog("[SplashScreen] '%@.json' NOT found in bundle", animationName)
            return nil
        }
        NSLog("[SplashScreen] Found at: %@", path)
        guard let animation = LottieAnimation.filepath(path) else {
            NSLog("[SplashScreen] Failed to parse Lottie animation")
            return nil
        }
        NSLog("[SplashScreen] Lottie animation parsed OK")

        let animationView = LottieAnimationView(animation: animation)
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore

        // Force first frame to render synchronously before the window becomes visible
        animationView.currentProgress = 0
        animationView.forceDisplayUpdate()

        let vc = UIViewController()
        vc.view = animationView

        animationView.play()
        lottieView = animationView

        return vc
    }
    #endif

    // MARK: - JS Load Error Auto-Hide

    /// Observes React Native JS bundle load failure.
    /// If the bundle fails to load, the splash is hidden automatically so
    /// the developer can see the RedBox / LogBox error screen.
    private static func observeJSLoadError() {
        guard jsErrorObserver == nil else { return }
        jsErrorObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RCTJavaScriptDidFailToLoadNotification"),
            object: nil,
            queue: .main
        ) { _ in
            NSLog("[SplashScreen] JS bundle failed to load — auto-hiding splash")
            hideSplash()
        }
    }

    private static func removeJSErrorObserver() {
        guard let obs = jsErrorObserver else { return }
        NotificationCenter.default.removeObserver(obs)
        jsErrorObserver = nil
    }

    // MARK: - Helpers

    private static var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    private static func removeSceneObserver() {
        guard let obs = sceneObserver else { return }
        NotificationCenter.default.removeObserver(obs)
        sceneObserver = nil
    }

    private static func onMainThread(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() }
        else { DispatchQueue.main.async(execute: work) }
    }
}
