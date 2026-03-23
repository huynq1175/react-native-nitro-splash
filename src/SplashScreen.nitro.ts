import type { HybridObject } from 'react-native-nitro-modules';

export interface SplashScreen
  extends HybridObject<{ ios: 'swift'; android: 'kotlin' }> {
  show(): void;
  hide(): void;
}
