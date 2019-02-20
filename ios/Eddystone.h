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

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface Eddystone : RCTEventEmitter <RCTBridgeModule>
/**
   * Eddystone class initializer
   * @return instancetype
   */
- (instancetype)init;
@end
