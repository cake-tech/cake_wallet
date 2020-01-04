#import "CwMoneroPlugin.h"
#import <cw_monero/cw_monero-Swift.h>

@implementation CwMoneroPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwMoneroPlugin registerWithRegistrar:registrar];
}
@end
