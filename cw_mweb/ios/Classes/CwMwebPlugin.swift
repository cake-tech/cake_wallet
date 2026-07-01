import Flutter
import UIKit

public class CwMwebPlugin: NSObject, FlutterPlugin {
public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cw_mweb", binaryMessenger: registrar.messenger())
        let instance = CwMwebPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }


    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
}
