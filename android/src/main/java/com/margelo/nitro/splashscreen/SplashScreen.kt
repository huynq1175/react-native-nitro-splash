package com.margelo.nitro.splashscreen

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.app.Activity
import android.app.Dialog
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.view.WindowCompat
import com.facebook.proguard.annotations.DoNotStrip
import com.facebook.react.bridge.UiThreadUtil
import java.lang.ref.WeakReference

/**
 * A splash screen module for React Native using NitroModules.
 *
 * Displays a full-screen Dialog backed by `launch_screen.xml` layout resource,
 * with an optional Lottie animation overlay on top (when `lottie-react-native`
 * is installed in the app).
 *
 * Auto-hides the splash if the JS bundle fails to load, so the developer can
 * see the RedBox error screen. On Android this is done via a safety-timeout
 * that fires only if `hide()` was never called from JS.
 */
@DoNotStrip
class SplashScreen : HybridSplashScreenSpec() {

    override fun show() = showSplash()
    override fun hide() = hideSplash()

    companion object {
        private const val TAG = "SplashScreen"
        private const val LAYOUT_NAME = "launch_screen"
        private const val LAYOUT_DEF_TYPE = "layout"
        private const val FADE_OUT_DURATION = 250L

        /**
         * Safety timeout (ms) — if the splash is still visible after this duration,
         * it is automatically hidden. This covers JS bundle load failures where
         * `hide()` is never called from JS. Set to 0 to disable.
         * Default: 10 seconds.
         */
        var autoHideTimeout: Long = 10_000L

        private var splashDialog: Dialog? = null
        private var activityRef: WeakReference<Activity>? = null
        private val mainHandler = Handler(Looper.getMainLooper())
        private val autoHideRunnable = Runnable {
            if (splashDialog?.isShowing == true) {
                Log.w(TAG, "Splash still visible after ${autoHideTimeout}ms — auto-hiding (JS bundle may have failed)")
                hideSplash()
            }
        }

        // ──────────────────── configuration ────────────────────

        var animationName: String = "splash_screen"
            private set

        @JvmStatic
        fun setAnimationName(name: String) {
            animationName = name
        }

        private fun resolveAnimationName(activity: Activity) {
            if (animationName != "splash_screen") return
            try {
                val appInfo = activity.packageManager.getApplicationInfo(
                    activity.packageName, android.content.pm.PackageManager.GET_META_DATA
                )
                val name = appInfo.metaData?.getString("SplashScreenAnimationName")
                if (!name.isNullOrEmpty()) {
                    animationName = name
                }
            } catch (_: Exception) {}
        }

        // ──────────────────── public API ────────────────────

        @JvmStatic
        fun show(activity: Activity, themeResId: Int = 0) {
            activityRef = WeakReference(activity)
            resolveAnimationName(activity)
            showDialog(activity, themeResId)
        }

        @JvmStatic
        fun showSplash() {
            activityRef?.get()?.let { showDialog(it) }
        }

        @JvmStatic
        fun hideSplash() {
            // Cancel safety timeout — hide() was called normally
            mainHandler.removeCallbacks(autoHideRunnable)

            UiThreadUtil.runOnUiThread {
                val dialog = splashDialog ?: return@runOnUiThread
                if (!dialog.isShowing) return@runOnUiThread

                val decorView = dialog.window?.decorView ?: run {
                    dismissImmediately()
                    return@runOnUiThread
                }

                decorView.animate()
                    .alpha(0f)
                    .setDuration(FADE_OUT_DURATION)
                    .setListener(object : AnimatorListenerAdapter() {
                        override fun onAnimationEnd(animation: Animator) {
                            dismissImmediately()
                        }
                    })
                    .start()
            }
        }

        private fun dismissImmediately() {
            try { LottieHelper.stop(splashDialog?.window?.decorView) } catch (_: Exception) {}
            splashDialog?.run { if (isShowing) dismiss() }
            splashDialog = null
        }

        // ──────────────────── internals ────────────────────

        private fun showDialog(activity: Activity, themeResId: Int = 0) {
            UiThreadUtil.runOnUiThread {
                if (splashDialog?.isShowing == true) return@runOnUiThread

                val layoutId = activity.resources.getIdentifier(
                    LAYOUT_NAME, LAYOUT_DEF_TYPE, activity.packageName
                )
                if (layoutId == 0) return@runOnUiThread

                val theme = if (themeResId != 0) themeResId
                    else android.R.style.Theme_Light_NoTitleBar

                val container = FrameLayout(activity)

                val staticView = activity.layoutInflater.inflate(layoutId, container, false)
                container.addView(staticView, matchParentParams())

                // Lottie overlay — no-op if lottie-react-native is not installed
                try { LottieHelper.addOverlay(activity, container, animationName) }
                catch (_: Exception) {}

                val dialog = Dialog(activity, theme).apply {
                    setContentView(container)
                    setCancelable(false)
                }

                dialog.window?.applyEdgeToEdge()

                dialog.show()
                splashDialog = dialog

                // Start safety timeout
                if (autoHideTimeout > 0) {
                    mainHandler.removeCallbacks(autoHideRunnable)
                    mainHandler.postDelayed(autoHideRunnable, autoHideTimeout)
                }
            }
        }

        // ──────────────────── helpers ────────────────────

        private fun matchParentParams() = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )

        private fun android.view.Window.applyEdgeToEdge() {
            WindowCompat.setDecorFitsSystemWindows(this, false)

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) {
                @Suppress("DEPRECATION")
                statusBarColor = android.graphics.Color.TRANSPARENT
                @Suppress("DEPRECATION")
                navigationBarColor = android.graphics.Color.TRANSPARENT
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                @Suppress("DEPRECATION")
                decorView.systemUiVisibility =
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            }

            setLayout(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT
            )
            addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
        }
    }
}
