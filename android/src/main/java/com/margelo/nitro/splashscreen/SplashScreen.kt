package com.margelo.nitro.splashscreen
  
import com.facebook.proguard.annotations.DoNotStrip

@DoNotStrip
class SplashScreen : HybridSplashScreenSpec() {
  override fun multiply(a: Double, b: Double): Double {
    return a * b
  }
}
