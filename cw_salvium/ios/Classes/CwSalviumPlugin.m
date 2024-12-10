#import "CwSalviumPlugin.h"
#if __has_include(<cw_salvium/cw_salvium-Swift.h>)
#import <cw_salvium/cw_salvium-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cw_salvium-Swift.h"
#endif

@implementation CwSalviumPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwSalviumPlugin registerWithRegistrar:registrar];
}
@end
