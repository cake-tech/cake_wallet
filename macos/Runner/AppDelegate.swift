import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController

        let utilsChannel = FlutterMethodChannel(
            name: "com.cake_wallet/native_utils",
            binaryMessenger: controller.engine.binaryMessenger)
        utilsChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "sec_random":
                guard let args = call.arguments as? Dictionary<String, Any>,
                      let count = args["count"] as? Int else {
                    result(nil)
                    return
                }

                result(secRandom(count: count))

            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
}
