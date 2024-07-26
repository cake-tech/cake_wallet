import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'cw_mweb_platform_interface.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static RpcClient? _rpcClient;
  static ClientChannel? _clientChannel;
  static int? _port;

  static Future<void> _initializeClient() async {
    final appDir = await getApplicationSupportDirectory();
    _port = await CwMwebPlatform.instance.start(appDir.path);
    if (_port == null || _port == 0) {
      throw Exception("Failed to start server");
    }
    print("Attempting to connect to server on port: $_port");

    _clientChannel = ClientChannel('127.0.0.1',
        port: _port!,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          keepAlive: ClientKeepAliveOptions(permitWithoutCalls: true),
        ));
    _rpcClient = RpcClient(_clientChannel!);
  }

  static Future<RpcClient> stub({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        if (_rpcClient != null) {
          // Try to use the existing connection
          final status = await _rpcClient!
              .status(StatusRequest(), options: CallOptions(timeout: const Duration(seconds: 3)));
          if (status.blockTime == 0) {
            throw Exception("blockTime shouldn't be 0! (1)");
          }
          return _rpcClient!;
        } else {
          await _initializeClient();
          // make sure the connection works:
          final status = await _rpcClient!
              .status(StatusRequest(), options: CallOptions(timeout: const Duration(seconds: 3)));
          if (status.blockTime == 0) {
            throw Exception("blockTime shouldn't be 0! (2)");
          }
          return _rpcClient!;
        }
      } catch (e) {
        print("Attempt $i failed: $e");
        if (i == maxRetries - 1) rethrow;
        await stop(); // call stop so we create a new instance before retrying
        await Future.delayed(Duration(seconds: 2)); // Wait before retrying
      }
    }
    throw Exception("Failed to connect after $maxRetries attempts");
  }

  static Future<void> stop() async {
    await CwMwebPlatform.instance.stop();
    await cleanup();
  }

  static Future<void> cleanup() async {
    await _clientChannel?.terminate();
    _rpcClient = null;
    _clientChannel = null;
    _port = null;
  }
}
