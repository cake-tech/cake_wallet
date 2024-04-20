import 'package:grpc/grpc.dart';
import 'cw_mweb_platform_interface.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static Future<bool?> start(String dataDir) {
    return CwMwebPlatform.instance.start(dataDir);
  }

  static stub() {
    final channel = ClientChannel('127.0.0.1',
      port: 12345,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure()));
    return RpcClient(channel);
  }
}
