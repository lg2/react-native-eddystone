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

package com.lg2.eddystone;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter;

import android.bluetooth.*;
import android.bluetooth.le.*;
import android.os.ParcelUuid;

import java.util.List;
import java.util.ArrayList;

public class EddystoneModule extends ReactContextBaseJavaModule {
  /** @property {ReactApplicationContext} The react app context */
  private final ReactApplicationContext reactContext;

  /** @property {BluetoothAdapter} The Bluetooth Adapter instance */
  private BluetoothAdapter bluetoothAdapter;

  /** @property {BluetoothLeScanner} The Bluetooth LE scanner instance */
  private BluetoothLeScanner scanner;

  /** @property ParcelUuid The service id for Eddystone beacons */
  public static final ParcelUuid SERVICE_UUID = ParcelUuid.fromString("0000FEAA-0000-1000-8000-00805F9B34FB");

  /** @property ParcelUuid The configuration service id for Eddystone beacon */
  public static final ParcelUuid CONFIGURATION_UUID = ParcelUuid.fromString("a3c87500-8ed3-4bdf-8a39-a01bebede295");

  /** @property byte UID frame type byte identifier */
  public static final byte FRAME_TYPE_UID = 0x00;

  /** @property byte URL frame type byte identifier */
  public static final byte FRAME_TYPE_URL = 0x10;

  /** @property byte TLM frame type byte identifier */
  public static final byte FRAME_TYPE_TLM = 0x20;

  /** @property byte EID frame type byte identifier */
  public static final byte FRAME_TYPE_EID = 0x30;

  /** @property byte Empty frame type byte identifier */
  public static final byte FRAME_TYPE_EMPTY = 0x40;

  /**
   * EddystoneModule class constructor
   * 
   * @param {ReactApplicationContext} reactContext React native application
   *        context
   * @constructor
   */
  public EddystoneModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
  }

  /**
   * Returns the name of the module
   * 
   * @returns {String} The name of the module
   * @public
   */
  @Override
  public String getName() {
    return "Eddystone";
  }

  /**
   * Dispatches an event to the javascript thread
   * 
   * @param {String} event The name of the dispatched event
   * @param {Object} params The parameters related to that event
   * @returns {void}
   * @public
   */
  private void emit(String event, Object params) {
    reactContext.getJSModule(RCTDeviceEventEmitter.class).emit(event, params);
  }

  /**
   * Returns a URL scheme based on a URL Frame hexChar
   * 
   * @param {byte} The hexChar to analyse for a scheme
   * @returns {String} The URL scheme found
   * @public
   */
  private String getURLScheme(byte hexChar) {
    switch (hexChar) {
    case 0x00:
      return "http://www.";
    case 0x01:
      return "https://www.";
    case 0x02:
      return "http://";
    case 0x03:
      return "https://";
    default:
      return null;
    }
  }

  /**
   * Returns an encoded string or URL suffix based on a URL frame hexChar
   * 
   * @param {byte} hexChar The hexChar to analyse for a scheme
   * @returns {String} The encoded string or URL suffix found
   * @public
   */
  private String getEncodedString(byte hexChar) {
    switch (hexChar) {
    case 0x00:
      return ".com/";
    case 0x01:
      return ".org/";
    case 0x02:
      return ".edu/";
    case 0x03:
      return ".net/";
    case 0x04:
      return ".info/";
    case 0x05:
      return ".biz/";
    case 0x06:
      return ".gov/";
    case 0x07:
      return ".com";
    case 0x08:
      return ".org";
    case 0x09:
      return ".edu";
    case 0x0a:
      return ".net";
    case 0x0b:
      return ".info";
    case 0x0c:
      return ".biz";
    case 0x0d:
      return ".gov";
    default:
      byte[] byteArray = new byte[] { hexChar };
      return new String(byteArray);
    }
  }

  /** @property {ScanCallback} Callbacks execute when a device is scanned */
  ScanCallback scanCallback = new ScanCallback() {
    /**
     * Triggered when a device is scanned
     * 
     * @param {int} callbackType The type of callback triggered
     * @param {ScanResult} result The device result object
     * @returns {void}
     * @public
     */
    @Override
    public void onScanResult(int callbackType, ScanResult result) {
      handleResult(result);
    }

    /**
     * Triggered when many devices were scanned
     * 
     * @param {List<ScanResult>} results The devices results objects
     * @returns {void}
     * @public
     */
    @Override
    public void onBatchScanResults(List<ScanResult> results) {
      for (ScanResult result : results) {
        handleResult(result);
      }
    }

    /**
     * Handles a single device's results
     * 
     * @param {ScanResult} result The device's result object
     * @returns {void}
     * @public
     */
    public void handleResult(ScanResult result) {
      // attempt to get sevice data from eddystone uuid
      byte[] serviceData = result.getScanRecord().getServiceData(SERVICE_UUID);

      // fallback on configuration uuid if necessary
      if (serviceData == null || serviceData.length == 0) {
        serviceData = result.getScanRecord().getServiceData(CONFIGURATION_UUID);

        if (serviceData == null) {
          return;
        }
      }

      // handle all possible frame types
      byte frameType = serviceData[0];
      if (frameType == FRAME_TYPE_UID || frameType == FRAME_TYPE_EID) {
        int length = 16;
        String event = "onUIDFrame";

        if (frameType == FRAME_TYPE_EID) {
          length = 8;
          event = "onEIDFrame";
        }

        // reconstruct the beacon id from hex array
        StringBuilder builder = new StringBuilder();
        for (int i = 2; i < length; i++) {
          builder.append(Integer.toHexString(serviceData[i] & 0xFF));
        }

        // create params object for javascript thread
        WritableMap params = Arguments.createMap();
        params.putString("id", builder.toString());
        params.putString("uid", result.getDevice().getAddress());
        params.putInt("txPower", serviceData[1]);
        params.putInt("rssi", result.getRssi());

        // dispatch event
        emit(event, params);
      } else if (frameType == FRAME_TYPE_URL) {

        // build the url from the frame's bytes
        String url = getURLScheme(serviceData[2]);
        for (int i = 3; i < 17; i++) {
          if (serviceData.length <= i) {
            break;
          }

          url += getEncodedString(serviceData[i]);
        }

        // dispatch event
        emit("onURLFrame", url);
      } else if (frameType == FRAME_TYPE_TLM) {
        // grab the beacon's voltage
        int voltage = (serviceData[2] & 0xFF) << 8;
        voltage += (serviceData[3] & 0xFF);

        // grab the beacon's temperature
        int temp = (serviceData[4] << 8);
        temp += (serviceData[5] & 0xFF);
        temp /= 256f;

        // create params object for javascript thread
        WritableMap params = Arguments.createMap();
        params.putInt("voltage", voltage);
        params.putInt("temp", temp);

        // dispatch event
        emit("onTelemetryFrame", params);
      } else if (frameType == FRAME_TYPE_EMPTY) {
        // dispatch empty event
        emit("onEmptyFrame", null);
      }
    }
  };

  /**
   * Starts scanning for Eddystone beacons
   * 
   * @returns {void}
   * @public
   */
  @ReactMethod
  public void startScanning() {
    ScanFilter serviceFilter = new ScanFilter.Builder().setServiceUuid(SERVICE_UUID).build();

    ScanFilter configurationFilter = new ScanFilter.Builder().setServiceUuid(CONFIGURATION_UUID).build();

    final List<ScanFilter> filters = new ArrayList<>();
    filters.add(serviceFilter);
    filters.add(configurationFilter);

    ScanSettings settings = new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build();

    // start scanning
    scanner = bluetoothAdapter.getBluetoothLeScanner();
    scanner.startScan(filters, settings, scanCallback);
  }

  /**
   * Stops scanning for Eddystone beacons
   * 
   * @returns {void}
   * @public
   */
  @ReactMethod
  public void stopScanning() {
    scanner.stopScan(scanCallback);
    scanner = null;
  }
}