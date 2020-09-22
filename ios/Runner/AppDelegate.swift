import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(name: "com.cakewallet.cakewallet/legacy_wallet_migration",
                                                  binaryMessenger: controller.binaryMessenger)
        batteryChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            switch call.method {
            case "read_trade_list":
                guard let args = call.arguments as? Dictionary<String, Any>,
                      let key = args["key"] as? String,
                      let salt = args["salt"] as? String else {
                    return
                }
                let normalizedKey = key.replacingOccurrences(of: "-", with: "")
                result(readTradesList(key: normalizedKey, salt: salt))
            case "read_encrypted_file":
                guard let args = call.arguments as? Dictionary<String, Any>,
                      let path = args["path"] as? String,
                      let key = args["key"] as? String,
                      let salt = args["salt"] as? String else {
                    return
                }
                
                let content = EncryptedFile(url: URL(fileURLWithPath: path), key: key, salt: salt).decryptedContent()
                result(content)
            default:
                break
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
