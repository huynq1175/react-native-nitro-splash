// Include C++ umbrella FIRST so that SplashScreen-Swift.h can reference
// the margelo::nitro namespace types it needs.
#if __has_include("SplashScreen-Swift-Cxx-Umbrella.hpp")
  #include "SplashScreen-Swift-Cxx-Umbrella.hpp"
#elif __has_include(<SplashScreen/SplashScreen-Swift-Cxx-Umbrella.hpp>)
  #include <SplashScreen/SplashScreen-Swift-Cxx-Umbrella.hpp>
#endif

#import <Foundation/Foundation.h>

/// Automatically shows the splash screen on app launch.
///
/// `+load` is invoked when the binary is loaded — before `main()` and before
/// `application:didFinishLaunchingWithOptions:`. The actual UI work is dispatched
/// to the main queue so it runs as the very first main-queue block.
@interface SplashScreenAutoShow : NSObject
@end

@implementation SplashScreenAutoShow

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SplashScreenBridge autoShow];
    });
}

@end
