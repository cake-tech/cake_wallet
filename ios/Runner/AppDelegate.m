#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    UIViewController *blankViewController = [UIViewController new];
    blankViewController.view.backgroundColor = [UIColor blackColor];
    [self.window.rootViewController presentViewController:blankViewController animated:NO completion:NULL];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:NO];
}

@end
