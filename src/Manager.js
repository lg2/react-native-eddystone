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
import { startScanning, stopScanning, startService, stopService } from "./NativeModule";
import { addListener, removeListener } from "./NativeEventEmitter";

class Manager extends EventEmitter {
  /**
   * Manager class constructor
   * @param {number} expiration Beacon expiration time in milliseconds
   */
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

  /**
   * Starts scanning for beacons
   * @returns {void}
   */
  start() {
    addListener("onUIDFrame", this.events.addBeacon);
    addListener("onEIDFrame", this.events.addBeacon);
    addListener("onURLFrame", this.events.addUrl);
    addListener("onTelemetryFrame", this.events.addTelemetry);

    startScanning();
    startService();
  }

  /**
   * Stops scanning for beacons
   * @returns {void}
   */
  stop() {
    removeListener("onUIDFrame", this.events.addBeacon);
    removeListener("onEIDFrame", this.events.addBeacon);
    removeListener("onURLFrame", this.events.addUrl);
    removeListener("onTelemetryFrame", this.events.addTelemetry);

    stopScanning();
    stopService();
  }

  /**
   * Checks whether or not the manager has cached the beacon uid or not
   * @param {string} uid The beacon uid to look for
   * @returns {boolean}
   */
  has(uid) {
    return this.beacons.filter(beacon => uid === beacon.uid).length > 0;
  }

  /**
   * Adds a beacon to the manager's cache if it does not exist
   * @param {BeaconData} data The beacons UID/EID information
   * @returns {void}
   */
  addBeacon(data) {
    if (!this.has(data.uid)) {
      const beacon = new Beacon(data, this);
      beacon.setExpiration(this.expiration);

      this.beacons.push(beacon);

      this.emit("onBeaconAdded", beacon);
    }
  }

  /**
   * Adds a URL to an existing beacon in the cache
   * @param {Beacon} beacon The beacon to add url to
   * @param {URLData} data The data containing the broadcasted URL
   * @returns {void}
   */
  addUrl(beacon, data) {
    beacon.url = data.url;
    beacon.setExpiration(this.expiration);

    this.emit("onBeaconUpdated", beacon);
  }

  /**
   * Adds telemetry info to an existing beacon in the cache
   * @param {Beacon} beacon The beacon to add telemetry to
   * @param {TelemetryData} data The data containing the broadcasted telemetry
   * @returns {void}
   */
  addTelemetry(beacon, data) {
    beacon.temp = data.temp;
    beacon.voltage = data.voltage;
    beacon.setExpiration(this.expiration);

    this.emit("onBeaconUpdated", beacon);
  }

  /**
   * Triggered when a beacon has reached the end of its life
   * @param {Beacon} beacon The expired beacon
   * @returns {void}
   */
  onBeaconExpires(beacon) {
    if (this.has(beacon.uid)) {
      this.beacons.splice(
        this.beacons.findIndex(({ uid }) => beacon.uid === uid),
        1
      );

      this.emit("onBeaconExpired", beacon);
    }
  }

  /**
   * Triggered when a beacon message has been received by the bluetooth manager
   * @param {BeaconData|URLData|TelemetryData} data The data received from the beacon
   * @param {Function} callback The callback that will handle this data
   * @returns {void}
   */
  _onData(data, callback) {
    if (this.has(data.uid)) {
      const index = this.beacons.findIndex(beacon => beacon.uid === data.uid);
      callback(this.beacons[index], data);
    }
  }
}

export default Manager;
