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
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "getPlatformVersion":
          result("iOS " + UIDevice.current.systemVersion)
      case "start":
          let args = call.arguments as? [String: String]
        //   print("args: \(args)")
          let dataDir = args?["dataDir"]
          var error: NSError?

          if dataDir == "stop" && CwMwebPlugin.server != nil {
              print("Stopping server")
              CwMwebPlugin.server?.stop()
              CwMwebPlugin.server = nil
              result(0)
              return
          }
          
          if CwMwebPlugin.server == nil {
              CwMwebPlugin.server = MwebdNewServer("", dataDir, "", &error)
              
              if let server = CwMwebPlugin.server {
                  do {
                      print("starting server \(CwMwebPlugin.port)")
                      try server.start(0, ret0_: &CwMwebPlugin.port)
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
//              result(FlutterError(code: "Server Already Running", message: "The server is already running", details: nil))
              result(CwMwebPlugin.port)
          }
      
      
      // result(0)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

    deinit {
        print("Stopping and cleaning up server")
        // Perform cleanup tasks
        CwMwebPlugin.server?.stop()
        CwMwebPlugin.server = nil
    }
}
