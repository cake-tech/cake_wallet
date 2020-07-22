import Foundation

struct FlutterMethodHandler {
    let name: String
    let handler: (FlutterMethodCall, @escaping FlutterResult) -> Void
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if name == call.method {
            handler(call, result)
        }
    }
}
