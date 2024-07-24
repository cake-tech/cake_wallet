import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'cw_mweb_platform_interface.dart';
import 'mwebd.pbgrpc.dart';

class CwMweb {
  static Future<RpcClient> stub() async {
    final appDir = await getApplicationSupportDirectory();
    int port = await CwMwebPlatform.instance.start(appDir.path) ?? 0;
    return RpcClient(
      ClientChannel('127.0.0.1',
          port: port,
          options: const ChannelOptions(
            credentials: ChannelCredentials.insecure(),
            keepAlive: ClientKeepAliveOptions(permitWithoutCalls: true),
          ), channelShutdownHandler: () {
        print("SHUTDOWN HANDLER CALLED @@@@@@@@@@@@@@@@@");
      }),
    );
  }

  static Future<void> stop() async {
    await CwMwebPlatform.instance.start("stop");
  }
}
