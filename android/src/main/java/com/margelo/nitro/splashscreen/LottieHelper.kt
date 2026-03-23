package com.margelo.nitro.splashscreen

import android.app.Activity
import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView

/**
 * Provides Lottie animation support using **pure reflection**.
 *
 * No compile-time dependency on `com.airbnb.android:lottie` — all class
 * and method references are resolved at runtime via [Class.forName].
 * This avoids duplicate-class issues with `lottie-react-native`'s codegen.
 *
 * If Lottie is not on the classpath (i.e. `lottie-react-native` is not
 * installed), every public method here throws [ClassNotFoundException]
 * which [SplashScreen] catches and ignores.
 */
internal object LottieHelper {

    private val lottieClass: Class<*> by lazy {
        Class.forName("com.airbnb.lottie.LottieAnimationView")
    }

    /**
     * Creates a `LottieAnimationView`, loads the named raw resource,
     * and adds it on top of [container].
     *
     * @throws ClassNotFoundException if Lottie is not available
     */
    fun addOverlay(activity: Activity, container: FrameLayout, animationName: String) {
        val rawId = activity.resources.getIdentifier(animationName, "raw", activity.packageName)
        if (rawId == 0) return

        // new LottieAnimationView(context)
        val view = lottieClass
            .getConstructor(Context::class.java)
            .newInstance(activity) as View

        // setAnimation(int rawRes)
        lottieClass
            .getMethod("setAnimation", Int::class.javaPrimitiveType)
            .invoke(view, rawId)

        // setRepeatCount(LottieDrawable.INFINITE) — INFINITE == Int.MAX_VALUE
        lottieClass
            .getMethod("setRepeatCount", Int::class.javaPrimitiveType)
            .invoke(view, Int.MAX_VALUE)

        // setScaleType(ImageView.ScaleType.CENTER_CROP)
        (view as ImageView).scaleType = ImageView.ScaleType.CENTER_CROP

        container.addView(
            view,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        // playAnimation()
        lottieClass.getMethod("playAnimation").invoke(view)
    }

    /**
     * Finds and stops any Lottie animation view inside [container].
     * No-op if Lottie is not available or no animation view is found.
     */
    fun stop(container: View?) {
        if (container == null) return
        try {
            // Find the LottieAnimationView in the dialog's view hierarchy
            val lottieView = findLottieView(container) ?: return
            lottieClass.getMethod("cancelAnimation").invoke(lottieView)
        } catch (_: Exception) { /* best-effort */ }
    }

    private fun findLottieView(view: View): View? {
        if (lottieClass.isInstance(view)) return view
        if (view is FrameLayout) {
            for (i in 0 until view.childCount) {
                val found = findLottieView(view.getChildAt(i))
                if (found != null) return found
            }
        }
        return null
    }
}
