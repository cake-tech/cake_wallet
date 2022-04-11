#import "FlutterLibmoneroPlugin.h"
#if __has_include(<flutter_libmonero/flutter_libmonero-Swift.h>)
#import <flutter_libmonero/flutter_libmonero-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_libmonero-Swift.h"
#endif

@implementation FlutterLibmoneroPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterLibmoneroPlugin registerWithRegistrar:registrar];
}
@end
