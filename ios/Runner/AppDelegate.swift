import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        DispatchQueue.main.async { [weak self] in
            self?.makeSecure()
        }

                
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }


  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

      let legacyMigrationChannel = FlutterMethodChannel(
                name: "com.cakewallet.cakewallet/legacy_wallet_migration",
                binaryMessenger: messenger)
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
                binaryMessenger: messenger)
            utilsChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                switch call.method {
                case "sec_random":
                    guard let args = call.arguments as? Dictionary<String, Any>,
                          let count = args["count"] as? Int else {
                        result(nil)
                        return
                    }

                    result(secRandom(count: count))

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
  }
    
    private var textField = UITextField()
    
private func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
}

private func makeSecure() {
    guard let window = self.window ?? keyWindow() else { return }

    if (!window.subviews.contains(textField)) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: textField.frame.self.width, height: textField.frame.self.height))
        window.addSubview(textField)
        window.layer.superlayer?.addSublayer(textField.layer)

        textField.layer.sublayers?.last?.addSublayer(window.layer)
        textField.leftView = view
        textField.leftViewMode = .always
    }
}

}