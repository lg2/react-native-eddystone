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

import { NativeModules } from "react-native";

const { Eddystone } = NativeModules;
const { startScanning, stopScanning } = Eddystone;

export { startScanning, stopScanning };
