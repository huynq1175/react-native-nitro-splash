package splashscreen.example

import android.os.Bundle
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate
import com.margelo.nitro.splashscreen.SplashScreen

class MainActivity : ReactActivity() {

  override fun getMainComponentName(): String = "SplashScreenExample"

  override fun createReactActivityDelegate(): ReactActivityDelegate =
      DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled)

  override fun onCreate(savedInstanceState: Bundle?) {
    // Show custom splash screen (Dialog with launch_screen.xml)
    // Theme has windowIsTranslucent=true so default Android splash is suppressed
    SplashScreen.show(this)
    super.onCreate(savedInstanceState)
  }
}
