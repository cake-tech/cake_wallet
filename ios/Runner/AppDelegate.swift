import UIKit
import Flutter
import UnstoppableDomainsResolution

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(name: "com.cakewallet.cakewallet/legacy_wallet_migration",
                                                  binaryMessenger: controller.binaryMessenger)
        let unstoppableDomainChannel = FlutterMethodChannel(name: "com.cakewallet.cake_wallet/unstoppable-domain", binaryMessenger: controller.binaryMessenger)
        
        batteryChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            switch call.method {
            case "decrypt":
                guard let args = call.arguments as? Dictionary<String, Any>,
                      let data = args["bytes"] as? FlutterStandardTypedData,
                      let key = args["key"] as? String,
                      let salt = args["salt"] as? String else {
                    result(nil)
                    return
                }
                
                let content = decrypt(data: data.data, key: key, salt: salt)
                result(content)
            case "read_user_defaults":
                guard let args = call.arguments as? Dictionary<String, Any>,
                      let key = args["key"] as? String,
                      let type = args["type"] as? String else {
                    result(nil)
                    return
                }
                
                var value: Any?
                
                switch (type) {
                case "string":
                    value = UserDefaults.standard.string(forKey: key)
                case "int":
                    value = UserDefaults.standard.integer(forKey: key)
                case "bool":
                    value = UserDefaults.standard.bool(forKey: key)
                default:
                    break
                }
                
                result(value)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        unstoppableDomainChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "getUnstoppableDomainAddress":
                guard let args = call.arguments as? Dictionary<String, String>,
                      let domain = args["domain"],
                      let ticker = args["ticker"] else {
                    result(nil)
                    return
                }
                
                guard let resolution = try? Resolution() else {
                    print ("Init of Resolution instance with default parameters failed...")
                    result(nil)
                    return
                }
                
                var address : String = ""
                
                resolution.addr(domain: domain, ticker: ticker) { result in
                  switch result {
                  case .success(let returnValue):
                    address = returnValue
                  case .failure(let error):
                    print("Expected Address, but got \(error)")
                }
                }
                
                result(address)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
