import { NitroModules } from 'react-native-nitro-modules';
import type { SplashScreen } from './SplashScreen.nitro';

const SplashScreenHybridObject =
  NitroModules.createHybridObject<SplashScreen>('SplashScreen');

export function multiply(a: number, b: number): number {
  return SplashScreenHybridObject.multiply(a, b);
}
