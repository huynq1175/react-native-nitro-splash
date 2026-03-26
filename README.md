# @abeman/react-native-nitro-splash

A high-performance splash screen for React Native, powered by [NitroModules](https://nitro.margelo.com/). Supports static storyboard/XML layouts and optional **Lottie animations**.

## Features

- Splash screen launches instantly with the app (before JS bundle loads)
- Controllable from both **native** and **JavaScript**
- Full-screen edge-to-edge display on iOS and Android
- Optional **Lottie animation** support (auto-detected, zero config)
- Smooth fade-out transition on hide
- Single splash instance shared across native and JS

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 13.0+          |
| Android  | SDK 24+        |
| React Native | 0.73+     |
| react-native-nitro-modules | ^0.35.2 |

## Installation

```sh
npm install @abeman/react-native-nitro-splash react-native-nitro-modules
```

### iOS

```sh
cd ios && pod install
```

### Android

No additional steps — auto-linked via Gradle.

### Optional: Lottie Animation Support

```sh
npm install lottie-react-native
```

When `lottie-react-native` is installed, Lottie support is **automatically enabled** at build time — no additional configuration needed.

## Setup

### iOS Setup

#### 1. Create `LaunchScreen.storyboard`

Design your static splash screen in Xcode. This is shown by iOS **before any code runs**.

> **Tip:** If using Lottie, set the storyboard background color to match the first frame of your animation for a seamless transition.

#### 2. Auto-show on launch (already configured)

The splash screen auto-shows via `+load` in `SplashScreenBridge.mm` — no AppDelegate code needed.

The host app **does not** need to `import SplashScreen`. The ObjC bridge handles everything internally.

#### 3. (Optional) Lottie animation

Add your Lottie JSON file to the Xcode project:
1. Drag `splash_screen.json` into your app target in Xcode
2. Ensure it's added to **"Copy Bundle Resources"** in Build Phases

To use a custom file name, add to `Info.plist`:
```xml
<key>SplashScreenAnimationName</key>
<string>my_custom_animation</string>
```

> **Note:** Do NOT `import SplashScreen` in AppDelegate — C++ headers in NitroModules cause build failures. Use `Info.plist` for configuration instead.

### Android Setup

#### 1. Create `launch_screen.xml`

Create a layout file at `android/app/src/main/res/layout/launch_screen.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:background="#FFFFFF">

    <!-- Your splash content here -->
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="My App"
        android:textSize="36sp"
        android:textStyle="bold" />
</LinearLayout>
```

#### 2. Suppress default Android splash

Add `windowIsTranslucent` to your app theme in `android/app/src/main/res/values/styles.xml`:

```xml
<style name="AppTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
    <item name="android:windowIsTranslucent">true</item>
</style>
```

This prevents the default Android 12+ system splash from showing.

#### 3. Show splash in MainActivity

```kotlin
import android.os.Bundle
import com.margelo.nitro.splashscreen.SplashScreen

class MainActivity : ReactActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        SplashScreen.show(this)
        super.onCreate(savedInstanceState)
    }

    // ...
}
```

#### 4. (Optional) Lottie animation

Place your Lottie JSON file at `android/app/src/main/res/raw/splash_screen.json`.

To use a custom file name, either call before `show()` in MainActivity:
```kotlin
SplashScreen.setAnimationName("my_custom_animation")
SplashScreen.show(this)
```

Or add meta-data to `AndroidManifest.xml` (no code change needed):
```xml
<application ...>
    <meta-data
        android:name="SplashScreenAnimationName"
        android:value="my_custom_animation" />
</application>
```

## Usage (JavaScript)

```typescript
import SplashScreen from '@abeman/react-native-nitro-splash';

// Hide the splash screen (e.g., after data loads)
SplashScreen.hide();

// Show the splash screen again
SplashScreen.show();
```

### Typical pattern

```typescript
import { useEffect } from 'react';
import SplashScreen from '@abeman/react-native-nitro-splash';

export default function App() {
  useEffect(() => {
    async function init() {
      await loadMyAppConfigs();
      SplashScreen.hide();
    }
    init();
  }, []);

  return <MyApp />;
}
```

## API

| Method | Description |
|--------|-------------|
| `SplashScreen.show()` | Show the splash screen. Callable from both JS and native. |
| `SplashScreen.hide()` | Hide the splash screen with a fade-out animation. |

Both methods control a **single shared splash instance** across the entire app.

## How It Works

### iOS Flow

```
1. +load (SplashScreenBridge.mm)
   └─ dispatch_async(main_queue) → autoShow()
2. autoShow()
   └─ Wait for UIWindowScene → showWithScene()
3. showWithScene()
   ├─ Lottie JSON found? → LottieAnimationView as root VC
   └─ No Lottie?         → LaunchScreen.storyboard VC
   └─ Create UIWindow (level: statusBar + 1) → makeKeyAndVisible
4. hide()
   └─ Stop Lottie → fade out 0.25s → remove window
```

### Android Flow

```
1. MainActivity.onCreate()
   └─ SplashScreen.show(activity)
2. showDialog()
   ├─ Inflate launch_screen.xml into FrameLayout
   ├─ Lottie raw resource found? → Add LottieAnimationView overlay (via reflection)
   └─ Show full-screen Dialog (edge-to-edge, transparent system bars)
3. hide()
   └─ Cancel Lottie → fade out 250ms → dismiss dialog
```

## Lottie Support Details

Lottie is a **completely optional** dependency. The detection happens automatically at build time:

| | With `lottie-react-native` | Without |
|---|---|---|
| **iOS** | Podspec detects via Node resolve → adds `lottie-ios` dependency + `-DLOTTIE_INSTALLED` flag | Static storyboard only |
| **Android** | Lottie classes loaded via reflection at runtime | Static XML layout only |
| **Bundle size** | +~1.5MB (iOS), +~300KB (Android) | No overhead |

### Animation file lookup

| Platform | Location | Naming |
|----------|----------|--------|
| iOS | App bundle (Copy Bundle Resources) | `{animationName}.json` |
| Android | `res/raw/` | `{animationName}.json` |

Default `animationName` is `"splash_screen"`. Override with `setAnimationName()` before showing.

## Architecture

This library uses [NitroModules](https://nitro.margelo.com/) HybridObject for the JS-native bridge. The native implementation follows the **ObjC-Compatible Bridge** pattern required for NitroModules on iOS:

```
┌─────────────────────────────────────────────┐
│  JavaScript                                 │
│  SplashScreen.show() / .hide()              │
└──────────────┬──────────────────────────────┘
               │ NitroModules HybridObject
┌──────────────▼──────────────────────────────┐
│  Native                                     │
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │ SplashScreen.kt │  │ SplashScreen.swift│  │
│  │ (HybridObject)  │  │ (HybridObject)   │  │
│  └────────┬────────┘  └────────┬─────────┘  │
│           │                    │             │
│  ┌────────▼────────┐  ┌───────▼──────────┐  │
│  │ Dialog + Layout  │  │ UIWindow + VC    │  │
│  │ + LottieHelper   │  │ + Lottie (opt)   │  │
│  └─────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────┘
```

> **Why the ObjC Bridge?** `SplashScreen` inherits from `HybridSplashScreenSpec` (a C++ class), making it invisible to the Objective-C runtime. `SplashScreenBridge` (an `NSObject` subclass) wraps the static API so `+load` and native callers can access it without importing C++ headers. See [CLAUDE.md](./CLAUDE.md) for details.

## Troubleshooting

### iOS: `'HybridObjectPrototype.hpp' file not found`

This happens when the host app tries to import the SplashScreen module directly. The C++ headers in NitroModules are not compatible with the Clang dependency scanner.

**Fix:** Never `import SplashScreen` in AppDelegate. The `+load` auto-show mechanism handles everything. If you need native access, use `SplashScreenBridge` via `NSClassFromString`.

### Android: `Platform declaration clash` (JVM signature)

NitroModules generates `abstract fun show()` / `abstract fun hide()`. If your companion object also has methods with the same name, JVM can't distinguish them.

**Fix:** Use distinct names for companion methods (e.g., `showSplash()` / `hideSplash()`).

### Android: `Type defined multiple times` (Lottie codegen)

React Native's codegen plugin generates `LottieAnimationViewManagerDelegate` in both the splash screen module and `lottie-react-native`.

**Fix:** The `build.gradle` excludes Lottie codegen classes from this module's output:
```gradle
afterEvaluate {
  tasks.withType(JavaCompile).configureEach { task ->
    task.exclude("com/facebook/react/viewmanagers/LottieAnimation*")
  }
}
```

### Android: Default system splash still shows

Android 12+ shows a system splash screen before your Activity starts.

**Fix:** Add `android:windowIsTranslucent=true` to your app theme to suppress it entirely.

### iOS: Storyboard flashes before Lottie animation

iOS always shows `LaunchScreen.storyboard` before any code runs. This is a platform limitation.

**Fix:** Set the storyboard background color to match the Lottie animation's first frame. The transition becomes imperceptible.

## License

MIT

---

Made with [NitroModules](https://nitro.margelo.com/)
