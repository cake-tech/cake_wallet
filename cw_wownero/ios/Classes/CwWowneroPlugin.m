#import "CwWowneroPlugin.h"
#import <cw_wownero/cw_wownero-Swift.h>

@implementation CwWowneroPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwWowneroPlugin registerWithRegistrar:registrar];
}
@end
