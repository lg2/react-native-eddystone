import { NativeModules, NativeEventEmitter } from "react-native";

const { Eddystone } = NativeModules;
const EddystoneEventEmitter = new NativeEventEmitter(Eddystone);

const startScanning = Eddystone.startScanning;
const stopScanning = Eddystone.stopScanning;
const addListener = EddystoneEventEmitter.addListener.bind(
  EddystoneEventEmitter
);

export default {
  startScanning,
  stopScanning,
  addListener
};
