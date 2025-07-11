import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:socks_socket/socks_socket.dart';

class ProxySocketSocks implements ProxySocket {
  final SOCKSSocket socket;

  ProxySocketSocks(this.socket);
  
  @override
  ProxyAddress get address => ProxyAddress(host: socket.proxyHost, port: socket.proxyPort);
  
  @override
  Future<void> close() => socket.close();
  
  @override
  void destroy() => close();
  
  @override
  void write(String data) => socket.write(data);

  @override
  StreamSubscription<List<int>> listen(Function(Uint8List event) onData, {Function(Object error)? onError, Function()? onDone, bool cancelOnError = true}) {
    return socket.listen(
      (data) {
        onData(Uint8List.fromList(data));
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

