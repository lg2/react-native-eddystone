#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface Eddystone : RCTEventEmitter <RCTBridgeModule>
  /**
   * Eddystone class initializer
   * @return instancetype
   */
  - (instancetype)init;
@end
