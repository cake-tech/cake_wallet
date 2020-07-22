import Flutter
import UIKit

public class SwiftCwMoneroPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cw_monero", binaryMessenger: registrar.messenger())
        syncListenerChannel = FlutterBasicMessageChannel(name: "cw_monero.sync_listener", binaryMessenger: registrar.messenger(), codec: FlutterBinaryCodec())
        let instance = SwiftCwMoneroPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private static var syncListenerChannel: FlutterBasicMessageChannel?
    private static var moneroWalletListener: MoneroWalletListener?
    private let handlers = [FlutterMethodHandler(name: "cw_monero.setupSyncStatusListener", handler: { (call, result) in
        let listener = MoneroWalletListener()
        listener.onNewBlock = { block in
            var _block = block
            let blockAsData = Data(bytes: &_block, count: MemoryLayout.size(ofValue: _block))
            var message = Data()
            message.append(0)
            message.append(blockAsData)
            syncListenerChannel?.sendMessage(message)
        }
        listener.onRefreshed = { _ in
            var message = Data()
            message.append(1)
            syncListenerChannel?.sendMessage(message)
        }
        listener.onUpdated = { _ in
            var message = Data()
            message.append(2)
            syncListenerChannel?.sendMessage(message)
        }
        listener.onMoneyReceived = { _, _ in
            var message = Data()
            message.append(3)
            syncListenerChannel?.sendMessage(message)
        }
        listener.onMoneySpent = { _, _ in
          var message = Data()
          message.append(4)
          syncListenerChannel?.sendMessage(message)
        }
        listener.onUnconfirmedMoneyReceived = { _, _ in
            var message = Data()
            message.append(5)
            syncListenerChannel?.sendMessage(message)
        }
        
        listener.setup()
        moneroWalletListener = listener
        result(true)
    })]
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        handlers.forEach { $0.handle(call, result: result) }
    }
}
