import UIKit
import Flutter
import UnstoppableDomainsResolution
import workmanager

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    lazy var resolution : Resolution? =  {
               return try? Resolution()
            }()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            // Registry in this case is the FlutterEngine that is created in Workmanager's
            // performFetchWithCompletionHandler or BGAppRefreshTask.
            // This will make other plugins available during a background operation.
            GeneratedPluginRegistrant.register(with: registry)
        }

        WorkmanagerPlugin.registerTask(withIdentifier: "com.fotolockr.cakewallet.monero_sync_task")

        makeSecure()
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let legacyMigrationChannel = FlutterMethodChannel(
            name: "com.cakewallet.cakewallet/legacy_wallet_migration",
            binaryMessenger: controller.binaryMessenger)
        legacyMigrationChannel.setMethodCallHandler({
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
        
        let utilsChannel = FlutterMethodChannel(
            name: "com.cake_wallet/native_utils",
            binaryMessenger: controller.binaryMessenger)
        utilsChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "sec_random":
                guard let args = call.arguments as? Dictionary<String, Any>,
                      let count = args["count"] as? Int else {
                    result(nil)
                    return
                }

                result(secRandom(count: count))
            case "getUnstoppableDomainAddress":
                guard let args = call.arguments as? Dictionary<String, String>,
                      let domain = args["domain"],
                      let ticker = args["ticker"],
                      let resolution = self?.resolution else {
                    result(nil)
                    return
                }
                        
                resolution.addr(domain: domain, ticker: ticker) { addrResult in
                  var address : String = ""
                    
                  switch addrResult {
                      case .success(let returnValue):
                        address = returnValue
                      case .failure(let error):
                        print("Expected Address, but got \(error)")
                    }
                    
                    result(address)
                }
            case "setIsAppSecure":
                guard let args = call.arguments as? Dictionary<String, Bool>,
                    let isAppSecure = args["isAppSecure"] else {
                    result(nil)
                    return
                }
                
                if isAppSecure {
                     self?.textField.isSecureTextEntry = true
                } else {
                    self?.textField.isSecureTextEntry = false
                }
                
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
                
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private var textField = UITextField()
    
    private func makeSecure() {
        if (!self.window.subviews.contains(textField)) {
            self.window.addSubview(textField)
            textField.centerYAnchor.constraint(equalTo: self.window.centerYAnchor).isActive = true
            textField.centerXAnchor.constraint(equalTo: self.window.centerXAnchor).isActive = true
            self.window.layer.superlayer?.addSublayer(textField.layer)
            textField.layer.sublayers?.first?.addSublayer(self.window.layer)
        }
    }

}
