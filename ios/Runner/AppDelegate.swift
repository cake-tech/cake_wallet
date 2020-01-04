import UIKit
import Flutter
import CWMonero

class MoneroWalletManagerHandler {
//    static let moneroWalletManager = MoneroWalletGateway()
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let moneroWalletManagerChannel = FlutterMethodChannel(name: "com.cakewallet.wallet/monero-wallet-manager",
                                              binaryMessenger: controller.binaryMessenger)
    moneroWalletManagerChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
    })
    
    moneroWalletManagerChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
        switch call.method {
        case "createWallet":
            result(1)
        case "isWalletExist":
            result(false)
        default:
            result(FlutterMethodNotImplemented)
        }
        
        result(1);
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
