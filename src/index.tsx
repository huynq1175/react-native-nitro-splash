import { NitroModules } from 'react-native-nitro-modules';
import type { SplashScreen } from './SplashScreen.nitro';

const SplashScreenModule =
  NitroModules.createHybridObject<SplashScreen>('SplashScreen');

export function show(): void {
  SplashScreenModule.show();
}

export function hide(): void {
  SplashScreenModule.hide();
}

export default { show, hide };
