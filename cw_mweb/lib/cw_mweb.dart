import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'cw_mweb_platform_interface.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static RpcClient? _rpcClient;
  static ClientChannel? _clientChannel;

  static Future<RpcClient> stub() async {
    final appDir = await getApplicationSupportDirectory();
    int port = await CwMwebPlatform.instance.start(appDir.path) ?? 0;
    _clientChannel = ClientChannel('127.0.0.1',
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          keepAlive: ClientKeepAliveOptions(permitWithoutCalls: true),
        ));
    _rpcClient = RpcClient(_clientChannel!);
    return _rpcClient!;
  }

  static Future<void> stop() async {
    await CwMwebPlatform.instance.start("stop");
    await cleanup();
  }

  static Future<void> cleanup() async {
    await _clientChannel?.terminate();
    _rpcClient = null;
    _clientChannel = null;
  }
}
