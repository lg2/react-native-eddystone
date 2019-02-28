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

class Beacon {
  constructor(data, manager) {
    this.id = data.id;
    this.uid = data.uid;
    this.rssi = data.rssi;
    this.txPower = data.txPower;

    this.url = null;
    this.temp = null;
    this.voltage = null;

    this.manager = manager;
  }

  setExpiration(time) {
    if (this.timeout) clearTimeout(this.timeout);
    this.timeout = setTimeout(() => this.manager.onBeaconExpires(this), time);
  }

  getDistance() {
    if (this.rssi == 0) return -1;

    const ratio = this.rssi / this.txPower;

    return (
      (ratio < 1.0
        ? Math.pow(ratio, 10)
        : 0.89976 * Math.pow(ratio, 7.7095) + 0.111) / 1000
    );
  }
}

export default Beacon;
