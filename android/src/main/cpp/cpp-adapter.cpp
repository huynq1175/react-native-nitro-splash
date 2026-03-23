#include <jni.h>
#include "splashscreenOnLoad.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return margelo::nitro::splashscreen::initialize(vm);
}
