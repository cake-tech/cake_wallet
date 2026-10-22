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
  // [connectionTimeout] only covers DNS + TCP; these bound the whole connect, including the SOCKS
  // and TLS handshakes, which otherwise can wait forever. Tor needs time to build a circuit.
  static const clearnetConnectDeadline = Duration(seconds: 20);
  static const torConnectDeadline = Duration(seconds: 60);

  static Future<ProxySocket> connect(bool sslEnabled, ProxyAddress address,
      {Duration? connectionTimeout}) {
    if (CakeTor.instance!.started) {
      SOCKSSocket? socksSocket;
      Future<ProxySocket> open() async {
        final socket = socksSocket = await SOCKSSocket.create(
          proxyHost: InternetAddress.loopbackIPv4.address,
          proxyPort: CakeTor.instance!.port,
          sslEnabled: sslEnabled,
        );
        await socket.connect();
        await socket.connectTo(address.host, address.port);
        return ProxySocketSocks(socket);
      }

      // Closing the SOCKS socket also fails a handshake that is still waiting on Tor.
      return _withDeadline(
        open(),
        torConnectDeadline,
        onTimeout: () => unawaited(socksSocket?.close().catchError((_) {})),
      );
    }
    if (sslEnabled == false) {
      return _withDeadline(
        Socket.connect(address.host, address.port, timeout: connectionTimeout)
            .then(ProxySocketInsecure.new),
        clearnetConnectDeadline,
      );
    } else {
      return _withDeadline(
        SecureSocket.connect(
          address.host,
          address.port,
          timeout: connectionTimeout,
          onBadCertificate: (_) => true,
        ).then(ProxySocketSecure.new),
        clearnetConnectDeadline,
      );
    }
  }

  /// Fails with a [TimeoutException] once [deadline] passes; a socket that still connects after
  /// that is destroyed instead of leaking.
  static Future<ProxySocket> _withDeadline(Future<ProxySocket> pending, Duration deadline,
      {void Function()? onTimeout}) async {
    try {
      return await pending.timeout(deadline);
    } on TimeoutException {
      onTimeout?.call();
      unawaited(pending.then((socket) => socket.destroy(), onError: (_) {}));
      rethrow;
    }
  }

  Future<void> close();
  void destroy();
  void write(String data);
  bool get isClosed;
  StreamSubscription<List<int>> listen(Function(Uint8List event) onData,
      {Function(Object error)? onError, Function()? onDone, bool cancelOnError = true});
  ProxyAddress get address;
}
