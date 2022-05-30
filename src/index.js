/**
 * React Native Eddystone
 *
 * A simple Eddystone implementation in React Native for both iOS and Android.
 *
 * @package    @lg2/react-native-eddystone
 * @link       https://github.com/lg2/react-native-eddystone
 * @copyright  2019 lg2
 * @license    MIT
 */

import Manager from "./Manager";
import { startScanning, stopScanning } from "./NativeModule.js";
import { addListener, removeListener } from "./NativeEventEmitter";

export default {
  startScanning,
  stopScanning,
  addListener,
  removeListener,
  Manager
};
