#import "CwMoneroPlugin.h"
#import <cw_monero/cw_monero-Swift.h>
//#include "../External/android/monero/include/wallet2_api.h"

@implementation CwMoneroPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwMoneroPlugin registerWithRegistrar:registrar];
}
@end
