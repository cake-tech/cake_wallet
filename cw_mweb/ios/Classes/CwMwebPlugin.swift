import Flutter
import UIKit
import Mwebd

public class CwMwebPlugin: NSObject, FlutterPlugin {
public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cw_mweb", binaryMessenger: registrar.messenger())
        let instance = CwMwebPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private static var server: MwebdServer?
    private static var port: Int = 0
    private static var dataDir: String?
    private static var nodeUri: String?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "getPlatformVersion":
                result("iOS " + UIDevice.current.systemVersion)
                break
            case "start":
                stopServer()
                let args = call.arguments as? [String: String]
                let dataDir = args?["dataDir"]
                let nodeUri = args?["nodeUri"]
                CwMwebPlugin.dataDir = dataDir
                CwMwebPlugin.nodeUri = nodeUri
                startServer(result: result)
                break
            case "stop":
                stopServer()
                result(nil)
                break
            // case "address":
            //     let args = call.arguments as! [String: Any]
            //     let scanSecret = args["scanSecret"] as! FlutterStandardTypedData
            //     let spendPub = args["spendPub"] as! FlutterStandardTypedData
            //     let index = args["index"] as! Int32
                
            //     let scanSecretData = scanSecret.data
            //     let spendPubData = spendPub.data
            //     result(MwebdAddress(scanSecretData, spendPubData, index))
            //     break
            case "addresses":
                let args = call.arguments as! [String: Any]
                let scanSecret = args["scanSecret"] as! FlutterStandardTypedData
                let spendPub = args["spendPub"] as! FlutterStandardTypedData
                let fromIndex = args["fromIndex"] as! Int32
                let toIndex = args["toIndex"] as! Int32
                
                let scanSecretData = scanSecret.data
                let spendPubData = spendPub.data
                result(MwebdAddresses(scanSecretData, spendPubData, fromIndex, toIndex))
                break
            default:
                result(FlutterMethodNotImplemented)
                break
        }
    }

    private func startServer(result: @escaping FlutterResult) {
        if CwMwebPlugin.server == nil {
            var error: NSError?
            CwMwebPlugin.server = MwebdNewServer("", CwMwebPlugin.dataDir, CwMwebPlugin.nodeUri, &error)

            if let server = CwMwebPlugin.server {
                do {
                    print("Starting server...")
                try server.start(0, ret0_: &CwMwebPlugin.port)
                    print("Server started successfully on port: \(CwMwebPlugin.port)")
                    result(CwMwebPlugin.port)
                } catch let startError as NSError {
                    print("Server Start Error: \(startError.localizedDescription)")
                    result(FlutterError(code: "Server Start Error", message: startError.localizedDescription, details: nil))
                }
            } else if let error = error {
                print("Server Creation Error: \(error.localizedDescription)")
                result(FlutterError(code: "Server Creation Error", message: error.localizedDescription, details: nil))
            } else {
                print("Unknown Error: Failed to create server")
                result(FlutterError(code: "Unknown Error", message: "Failed to create server", details: nil))
            }
        } else {
            print("Server already running on port: \(CwMwebPlugin.port)")
            result(CwMwebPlugin.port)
        }
    }

    private func stopServer() {
        print("Stopping server")
        CwMwebPlugin.server?.stop()
        CwMwebPlugin.server = nil
        CwMwebPlugin.port = 0
    }

    deinit {
        stopServer()
    }
}
