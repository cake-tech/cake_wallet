#import "CwHavenPlugin.h"
#if __has_include(<cw_haven/cw_haven-Swift.h>)
#import <cw_haven/cw_haven-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cw_haven-Swift.h"
#endif

@implementation CwHavenPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCwHavenPlugin registerWithRegistrar:registrar];
}
@end
