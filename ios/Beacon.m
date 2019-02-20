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

#import "Beacon.h"

@implementation Beacon
  @synthesize hash = _hash;

  /**
   * Returns Eddystone service id byte wrapped in a Core Bluetooth UUID
   * @return CBUUID * The Core Bluetooth UUID singleton instance
   */
  + (CBUUID *)getServiceId {
    static CBUUID *_singleton;
    static dispatch_once_t oncePredicate;

    // create Core Bluetooth UID singleton instance once
    dispatch_once(&oncePredicate, ^{
      _singleton = [CBUUID UUIDWithString:SERVICE_ID];
    });

    return _singleton;
  }

  /**
   * Returns beacon data based on a service data dictionary
   * @param NSDictionary * serviceData The service data dictionary
   * @return NSData * The beacon data
   */
  + (NSData *)getData:(NSDictionary *)serviceData {
    return serviceData[[Beacon getServiceId]];
  }

  /**
   * Returns a frame type based on a service data dictionary
   * @param NSDictionary serviceDate The service data dictionary
   * @return FrameType The identified frame type
   */
  + (FrameType)getFrameType:(NSDictionary *)serviceData {
    // retrieve the beacon data
    NSData *beaconData = [self getData:serviceData];

    // attempt to match a frame type
    if (beaconData) {
      uint8_t frameType;
      if ([beaconData length] > 1) {
        frameType = ((uint8_t *)[beaconData bytes])[0];
        switch (frameType) {
          case FRAME_TYPE_UID: return FrameTypeUID;
          case FRAME_TYPE_URL: return FrameTypeURL;
          case FRAME_TYPE_TLM: return FrameTypeTelemetry;
          case FRAME_TYPE_EID: return FrameTypeEID;
        }
      }
    }

    return FrameTypeUnknown;
  }

  /**
   * Initializes a new beacon instance from a UID frame type
   * @param NSDictionnary * serviceData The service data dictionnary
   * @param NSNumber * rssi The received signle strength indication
   * @return instancetype The newly created beacon instance
   */
  + (instancetype)initWithUIDFrameType:(NSDictionary *)serviceData
                                  rssi:(NSNumber *)rssi {
    // retrieve the beacon data
    NSData *beaconData = [self getData:serviceData];
    
    // read the bytes where UID data should be
    uint8_t frameType;
    [beaconData getBytes:&frameType length:1];
    if (frameType != FRAME_TYPE_UID) {
      return nil;
    }
    
    // create a frame field structure to hold the frame data
    UIDFrameFields uidFrame;
    
    // make sure the beacon data matches a UID frame field data size
    if ([beaconData length] == sizeof(UIDFrameFields)
          || [beaconData length] == sizeof(UIDFrameFields) - sizeof(uidFrame.RFU)) {
        // copy the beacon data bytes over to our structure
        [beaconData getBytes:&uidFrame length:(sizeof(UIDFrameFields)
                                               - sizeof(uidFrame.RFU))];
      
        // create a data structure with the beacon id bytes
        NSData *idData = [NSData dataWithBytes:&uidFrame.beaconId
                                        length:sizeof(uidFrame.beaconId)];
      
        // make sure we have a valid beacon id
        if(idData == nil) {
          return nil;
        }
      
        // create and return the new beacon object
        return [[Beacon alloc] initWithBeaconData:idData
                                             type:BeaconTypeUID
                                          txPower:@(uidFrame.txPower)
                                             rssi:rssi];
    }
    
    return nil;
  }

  /**
   * Initializes a new beacon instance from a EID frame type
   * @param NSDictionnary * serviceData The service data dictionnary
   * @param NSNumber * rssi The received signle strength indication
   * @return instancetype The newly created beacon instance
   */
  + (instancetype)initWithEIDFrameType:(NSDictionary *)serviceData
                                  rssi:(NSNumber *)rssi {
    // retrieve the beacon data
    NSData *beaconData = [self getData:serviceData];

    // read the bytes where UID data should be
    uint8_t frameType;
    [beaconData getBytes:&frameType length:1];
    if (frameType != FrameTypeEID) {
      return nil;
    }
    
    // create a frame field structure to hold the frame data
    EIDFrameFields eidFrame;
    
    // make sure the beacon data matches a UID frame field data size
    if ([beaconData length] == sizeof(EIDFrameFields)) {
      // copy the beacon data bytes over to our structure
      [beaconData getBytes:&eidFrame length:sizeof(EIDFrameFields)];
      
      // create a data structure with the beacon id bytes
      NSData *idData = [NSData dataWithBytes:&eidFrame.beaconId
                                      length:sizeof(eidFrame.beaconId)];

      // make sure we have a valid beacon id
      if(idData == nil) {
        return nil;
      }
      
      // create and return the new beacon object
      return [[Beacon alloc] initWithBeaconData:idData
                                           type:BeaconTypeUID
                                        txPower:@(eidFrame.txPower)
                                           rssi:rssi];
    }
    
    return nil;
  }

  /**
   * Initializes a new beacon instance from standard beacon data
   * @param NSData * id The broadcasted unique identifier
   * @param NSNumber * txPower The transmitted power measurement at one meter
   * @param NSNumber * rssi The received signle strength indication
   * @return instancetype The newly created beacon instance
   */
  - (instancetype)initWithBeaconData:(NSData *)id
                                type:(BeaconType)type
                             txPower:(NSNumber *)txPower
                                rssi:(NSNumber *)rssi {
    if ((self = [super init]) != nil) {
      // create regex to normalize id
      NSError *error = nil;
      NSRegularExpression *regex = [NSRegularExpression
                                    regularExpressionWithPattern:@"<|>|\\s"
                                    options:NSRegularExpressionCaseInsensitive
                                    error:&error];
     
      // convert id to a string
      NSString *idString = [NSString stringWithFormat:@"%@", id];
      
      _id = [regex
             stringByReplacingMatchesInString:idString
                                      options:0
                                        range:NSMakeRange(0, [idString length])
                                 withTemplate:@""];
      _type = type;
      _hash = 31 * self.type + [self.id hash];
      _txPower = txPower;
      _rssi = rssi;
    }
    
    return self;
  }

/**
 * Returns a fully qualified URL based on service data
 * @param NSDictionnary * serviceData The service data dictionnary
 * @return NSURL * The fully qualified URL object
 */
+ (NSURL *)getUrl:(NSDictionary *)serviceData {
  // retrieve the frame type & make sure it's a URL one
  FrameType frameType = [self getFrameType:serviceData];
  if(frameType != FrameTypeURL) {
    return nil;
  }
  
  // retrieve the beacon data & make sure it has data
  NSData *beaconData = [self getData:serviceData];
  if (!(beaconData.length > 0)) {
    return nil;
  }
  
  // store the URL information in a char buffer
  unsigned char urlFrame[20];
  [beaconData getBytes:&urlFrame length:beaconData.length];

  // get the URL scheme based on the buffer
  NSString *urlScheme = [self getURLScheme:*(urlFrame+2)];
  
  // transfer each bytes to the URL string
  NSString *urlString = urlScheme;
  for (int i = 0; i < beaconData.length - 3; i++) {
    urlString = [urlString stringByAppendingString:[self getEncodedString:*(urlFrame + i + 3)]];
  }

  return [NSURL URLWithString:urlString];
}

/**
 * Returns a URL scheme based on char byte value
 * @param char hexChar The bytes used to get a scheme
 * @return NSString * A string containing the URL scheme
 */
+ (NSString *)getURLScheme:(char)hexChar {
  switch (hexChar) {
    case 0x00:
      return @"http://www.";
    case 0x01:
      return @"https://www.";
    case 0x02:
      return @"http://";
    case 0x03:
      return @"https://";
    default:
      return nil;
  }
}

/**
 * Returns a URL suffix or an encoded string
 * @param char hexChar The bytes used to get the suffix/encoded string
 * @return NSString * A string containing the encode string
 */
+ (NSString *)getEncodedString:(char)hexChar {
  switch (hexChar) {
    case 0x00:
      return @".com/";
    case 0x01:
      return @".org/";
    case 0x02:
      return @".edu/";
    case 0x03:
      return @".net/";
    case 0x04:
      return @".info/";
    case 0x05:
      return @".biz/";
    case 0x06:
      return @".gov/";
    case 0x07:
      return @".com";
    case 0x08:
      return @".org";
    case 0x09:
      return @".edu";
    case 0x0a:
      return @".net";
    case 0x0b:
      return @".info";
    case 0x0c:
      return @".biz";
    case 0x0d:
      return @".gov";
    default:
      return [NSString stringWithFormat:@"%c", hexChar];
  }
}
@end
