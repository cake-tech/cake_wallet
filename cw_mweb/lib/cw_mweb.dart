import 'package:grpc/grpc.dart';
import 'cw_mweb_platform_interface.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static var port;

  static start(String dataDir) async {
    port = port ?? await CwMwebPlatform.instance.start(dataDir);
  }

  static stub() {
    return RpcClient(ClientChannel('127.0.0.1',
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure())));
  }
}
