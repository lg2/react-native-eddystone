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
 
#import <CoreBluetooth/CoreBluetooth.h>
#import "Eddystone.h"
#import "Beacon.h"

// declare our module interface & implement it as a central manager delegate
@interface Eddystone () <CBCentralManagerDelegate> {
@private
  /** @property BOOL Whether we should be scanning for devices or not */
  BOOL _shouldBeScanning;
  
  // core bluetooth central manager
  CBCentralManager *_centralManager;
  
  // our beacon dispatch queue
  dispatch_queue_t _beaconOperationsQueue;
}
@end

@implementation Eddystone
  // react-native module macro
  RCT_EXPORT_MODULE()

  // react native methods
  + (BOOL)requiresMainQueueSetup { return NO; }
  - (dispatch_queue_t)methodQueue { return dispatch_get_main_queue(); }

  /**
   * Eddystone class initializer
   * @return instancetype
   */
  - (instancetype)init {
    if ((self = [super init]) != nil) {
      _beaconOperationsQueue = dispatch_queue_create("EddystoneBeaconOperationsQueue", NULL);
      _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_beaconOperationsQueue];
    }

    return self;
  }

  /**
   * Lists the supported events for the RCTEventEmitter
   * @return NSArray<NSString *> * The supported events list
   */
  - (NSArray<NSString *> *)supportedEvents {
    return @[
             @"onUIDFrame",
             @"onEIDFrame",
             @"onURLFrame",
             @"onTelemetryFrame",
             @"onEmptyFrame",
             @"onStateChanged"
             ];
  }

  /**
   * Exported method that starts scanning for eddystone devices
   * @return void
   */
  RCT_EXPORT_METHOD(startScanning) {
    dispatch_async(_beaconOperationsQueue, ^{
      if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        _shouldBeScanning = YES;
      } else {
        NSArray *services = @[[CBUUID UUIDWithString:SERVICE_ID]];
        NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES };
        [_centralManager scanForPeripheralsWithServices:services options:options];
      }
    });
  }

  /**
   * Exported method that stops scanning for eddystone devices
   * @return void
   */
  RCT_EXPORT_METHOD(stopScanning) {
    _shouldBeScanning = NO;
    [_centralManager stopScan];
  }

  /**
   * Executes when the Core Bluetooth Central Manager discovered a peripheral
   * @param CBCentralManager * central Core Bluetooth Central Manager instance
   * @param CBPeripheral * peripheral Core Bluetooth peripheral instance
   * @param NSDictionary * advertisementData Peripheral advertised data
   * @param NSNumber * RSSI The received signal strength indication
   * @return void
   */
  - (void)centralManager:(CBCentralManager *)central
   didDiscoverPeripheral:(CBPeripheral *)peripheral
       advertisementData:(NSDictionary *)advertisementData
                    RSSI:(NSNumber *)RSSI {
    // retrieve the beacon data from the advertised data
    NSDictionary *serviceData = advertisementData[CBAdvertisementDataServiceDataKey];

    // retrieve the frame type
    FrameType frameType = [Beacon getFrameType:serviceData];
    
    // handle basic beacon broadcasts
    if (frameType == FrameTypeUID || frameType == FrameTypeEID) {
      // create our beacon object based on the frame type
      Beacon *beacon;
      NSString *eventName;
      if (frameType == FrameTypeUID) {
        eventName = @"onUIDFrame";
        beacon = [Beacon initWithUIDFrameType:serviceData rssi:RSSI];
      } else if(frameType == FrameTypeEID) {
        eventName = @"onEIDFrame";
        beacon = [Beacon initWithEIDFrameType:serviceData rssi:RSSI];
      }

      // dispatch device event with beacon information
      [self sendEventWithName:eventName
                         body:@{
                                @"id": [NSString stringWithFormat:@"%@", beacon.id],
                                @"uid": [peripheral.identifier UUIDString],
                                @"txPower": beacon.txPower,
                                @"rssi": beacon.rssi
                                }];
    } else if(frameType == FrameTypeURL) {
      // retrive the URL from the beacon broadcast & dispatch
      NSURL *url = [Beacon getUrl:serviceData];
      [self sendEventWithName:@"onURLFrame" body:@{
                                                  @"uid": [peripheral.identifier UUIDString],
                                                   @"url": url.absoluteString
                                                   }];
    } else if (frameType == FrameTypeTelemetry) {
      // retrieve the beacon data
      NSData *beaconData = [Beacon getData:serviceData];
      uint8_t *bytes = (uint8_t *)[beaconData bytes];
      
      // attempt to match a frame type
      if (beaconData) {
        if ([beaconData length] > 1) {
          int voltage = (bytes[2] & 0xFF) << 8;
          voltage += (bytes[3] & 0xFF);

          int temp = (bytes[4] << 8);
          temp += (bytes[5] & 0xFF);
          temp /= 256.f;
          
          // dispatch telemetry information
          [self sendEventWithName:@"onTelemetryFrame" body:@{
                                                             @"uid": [peripheral.identifier UUIDString],
                                                             @"voltage": [NSNumber numberWithInt: voltage],
                                                             @"temp": [NSNumber numberWithInt: temp]
                                                             }];
        }
      }

    } else if (frameType == FrameTypeEmpty){
      // dispatch empty frame
      [self sendEventWithName:@"onEmptyFrame" body:nil];
    }
  }

  /**
   * Executes when the Core Bluetooth Central Manager's state changes
   * @param CBCentralManager manager The Central Manager instance
   * @return void
   */
  - (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)manager {
    switch(manager.state) {
      case CBCentralManagerStatePoweredOn:
        [self sendEventWithName:@"onStateChanged" body:@"on"];
        if(_shouldBeScanning) {
          [self startScanning];
        }
        break;
        
      case CBCentralManagerStatePoweredOff:
        [self sendEventWithName:@"onStateChanged" body:@"off"];
        break;
        
      case CBCentralManagerStateResetting:
        [self sendEventWithName:@"onStateChanged" body:@"resetting"];
        break;
        
      case CBCentralManagerStateUnsupported:
        [self sendEventWithName:@"onStateChanged" body:@"unsupported"];
        break;
        
      case CBCentralManagerStateUnauthorized:
        [self sendEventWithName:@"onStateChanged" body:@"unauthorized"];
        break;
        
      default:
        [self sendEventWithName:@"onStateChanged" body:@"unknown"];
    }
  }
@end
