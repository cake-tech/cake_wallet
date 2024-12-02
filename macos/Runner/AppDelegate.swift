import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

@main
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
            case "setMinWindowSize":
                guard let self = self else {
                    result(false)
                    return
                }
                if let arguments = call.arguments as? [String: Any],
                   let width = arguments["width"] as? Double,
                   let height = arguments["height"] as? Double {
                    DispatchQueue.main.async {
                        self.mainFlutterWindow?.minSize = CGSize(width: width, height: height)
                    }
                    result(true)
                } else {
                    result(false)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
}
