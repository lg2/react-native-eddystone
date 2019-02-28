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

import Beacon from "./Beacon";
import EventEmitter from "eventemitter3";
import { startScanning, stopScanning } from "./NativeModule";
import { addListener, removeListener } from "./NativeEventEmitter";

class Manager extends EventEmitter {
  constructor(expiration) {
    super();

    this.beacons = [];
    this.expiration = expiration || 10000;
    this.events = {
      addBeacon: this.addBeacon.bind(this),
      addUrl: data => this._onData(data, this.addUrl.bind(this)),
      addTelemetry: data => this._onData(data, this.addTelemetry.bind(this))
    };
  }

  start() {
    addListener("onUIDFrame", this.events.addBeacon);
    addListener("onEIDFrame", this.events.addBeacon);
    addListener("onURLFrame", this.events.addUrl);
    addListener("onTelemetryFrame", this.events.addTelemetry);

    startScanning();
  }

  stop() {
    removeListener("onUIDFrame", this.events.addBeacon);
    removeListener("onEIDFrame", this.events.addBeacon);
    removeListener("onURLFrame", this.events.addUrl);
    removeListener("onTelemetryFrame", this.events.addTelemetry);

    stopScanning();
  }

  has(uid) {
    return this.beacons.filter(beacon => uid === beacon.uid).length > 0;
  }

  addBeacon(data) {
    if (!this.has(data.uid)) {
      const beacon = new Beacon(data, this);
      beacon.setExpiration(this.expiration);

      this.beacons.push(beacon);

      this.emit("onBeaconAdded", beacon);
    }
  }

  addUrl(beacon, data) {
    beacon.url = data.url;
    beacon.setExpiration(this.expiration);

    this.emit("onBeaconUpdated", beacon);
  }

  addTelemetry(beacon, data) {
    beacon.temp = data.temp;
    beacon.voltage = data.voltage;
    beacon.setExpiration(this.expiration);

    this.emit("onBeaconUpdated", beacon);
  }

  onBeaconExpires(beacon) {
    if (this.has(beacon.uid)) {
      this.beacons.splice(
        this.beacons.findIndex(({ uid }) => beacon.uid === uid),
        1
      );

      this.emit("onBeaconExpired", beacon);
    }
  }

  _onData(data, callback) {
    if (this.has(data.uid)) {
      const index = this.beacons.findIndex(beacon => beacon.uid === data.uid);
      callback(this.beacons[index], data);
    }
  }
}

export default Manager;
