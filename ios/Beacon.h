#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

// Eddystone's service id bytes
static NSString *const SERVICE_ID = @"FEAA";

// Enumerate the different frame type byte codes
static const uint8_t FRAME_TYPE_UID = 0x00;
static const uint8_t FRAME_TYPE_URL = 0x10;
static const uint8_t FRAME_TYPE_TLM = 0x20;
static const uint8_t FRAME_TYPE_EID = 0x30;
static const uint8_t FRAME_TYPE_EMPTY = 0x40;

// Enumereate the possible frame received from a beacon
// UnknownFrameType
typedef NS_ENUM(NSUInteger, FrameType) {
  FrameTypeUnknown = 0,
  FrameTypeUID,
  FrameTypeURL,
  FrameTypeTelemetry,
  FrameTypeEID,
  FrameTypeEmpty
};

// Enumerates the different possible beacon type
// EddystoneBeaconType: Unprotected broadcast
// EddystoneEIDBeaconTye: Enrypted broadcast
typedef NS_ENUM(NSUInteger, BeaconType) {
  BeaconTypeUID = 1,
  BeaconTypeEID = 2
};

// Defines a structure that matches Eddystone UID frame fields
typedef struct __attribute__((packed)) {
  uint8_t frameType;
  int8_t  txPower;
  uint8_t beaconId[16];
  uint8_t RFU[2];
} UIDFrameFields;

// Defines a structure that matches Eddystone EID frame fields
typedef struct __attribute__((packed)) {
  uint8_t frameType;
  int8_t  txPower;
  uint8_t beaconId[8];
} EIDFrameFields;

@interface Beacon : NSObject
  /** @property NSString The broadcasted unique identifier */
  @property(nonatomic, copy, readonly) NSString *id;

  /** @property BeaconType The broadcasted encryption type */
  @property(nonatomic, assign, readonly) BeaconType type;

  /** @property NSNumber The received signal strength indication */
  @property(nonatomic, strong, readonly) NSNumber *rssi;

  /** @property NSNumber The transmitted power measurement at one meter */
  @property(nonatomic, strong, readonly) NSNumber *txPower;

  /** @property NSData The broadcasted device telemetry */
  @property(nonatomic, copy, readonly) NSData *telemetry;

  /**
   * Returns Eddystone service id byte wrapped in a Core Bluetooth UUID
   * @return CBUUID * The Core Bluetooth UUID singleton instance
   */
  + (CBUUID *)getServiceId;

  /**
   * Returns beacon data based on a service data dictionary
   * @param NSDictionary * serviceData The service data dictionary
   * @return NSData * The beacon data
   */
  + (NSData *)getData:(NSDictionary *)serviceData;

  /**
   * Returns a frame type based on a service data dictionary
   * @param NSDictionary serviceDate The service data dictionary
   * @return FrameType The identified frame type
   */
  + (FrameType)getFrameType:(NSDictionary *)serviceData;

  /**
   * Initializes a new beacon instance from a UID frame type
   * @param NSDictionnary * serviceData The service data dictionnary
   * @param NSNumber * rssi The received signle strength indication
   * @return instancetype The newly created beacon instance
   */
  + (instancetype)initWithUIDFrameType:(NSDictionary *)serviceData
                                  rssi:(NSNumber *)rssi;

  /**
   * Initializes a new beacon instance from a EID frame type
   * @param NSDictionnary * serviceData The service data dictionnary
   * @param NSNumber * rssi The received signle strength indication
   * @return instancetype The newly created beacon instance
   */
  + (instancetype)initWithEIDFrameType:(NSDictionary *)serviceData
                                  rssi:(NSNumber *)rssi;

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
                                rssi:(NSNumber *)rssi;

  /**
   * Returns a fully qualified URL based on service data
   * @param NSDictionnary * serviceData The service data dictionnary
   * @return NSURL * The fully qualified URL object
   */
  + (NSURL *)getUrl:(NSDictionary *)serviceData;

  /**
   * Returns a URL scheme based on char byte value
   * @param char hexChar The bytes used to get a scheme
   * @return NSString * A string containing the URL scheme
   */
  + (NSString *)getURLScheme:(char)hexChar;

  /**
   * Returns a URL suffix or an encoded string
   * @param char hexChar The bytes used to get the suffix/encoded string
   * @return NSString * A string containing the encode string
   */
  + (NSString *)getEncodedString:(char)hexChar;
@end
