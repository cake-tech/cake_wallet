import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_core/utils/proxy_socket/insecure.dart';
import 'package:cw_core/utils/proxy_socket/secure.dart';
import 'package:cw_core/utils/proxy_socket/socks.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:socks_socket/socks_socket.dart';

class ProxyAddress {
  final String host;
  final int port;

  ProxyAddress({required this.host, required this.port});
}

abstract class ProxySocket {
  static Future<ProxySocket> connect(bool sslEnabled, ProxyAddress address, {Duration? connectionTimeout}) async {
    if (CakeTor.instance.started) {
      var socksSocket = await SOCKSSocket.create(
          proxyHost: InternetAddress.loopbackIPv4.address,
          proxyPort: CakeTor.instance.port,
          sslEnabled: sslEnabled,
      );
      await socksSocket.connect();
      await socksSocket.connectTo(address.host, address.port);
      return ProxySocketSocks(socksSocket);
    }
    if (sslEnabled == false) {
      return ProxySocketInsecure(await Socket.connect(address.host, address.port, timeout: connectionTimeout));
    } else {
      return ProxySocketSecure(await SecureSocket.connect(
        address.host,
        address.port,
        timeout: connectionTimeout,
        onBadCertificate: (_) => true,
      ));
    }
  }

  Future<void> close();
  void destroy();
  void write(String data);
  StreamSubscription<List<int>> listen(Function(Uint8List event) onData, {Function (Object error)? onError, Function ()? onDone, bool cancelOnError = true});
  ProxyAddress get address;
}