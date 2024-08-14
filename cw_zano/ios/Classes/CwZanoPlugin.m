#import "CwZanoPlugin.h"
#if __has_include(<cw_zano/cw_zano-Swift.h>)
#import <cw_zano/cw_zano-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cw_zano-Swift.h"
#endif

@implementation CwZanoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwZanoPlugin registerWithRegistrar:registrar];
}
@end
