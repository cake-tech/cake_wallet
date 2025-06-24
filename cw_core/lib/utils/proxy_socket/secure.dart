import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_core/utils/proxy_socket/abstract.dart';

class ProxySocketSecure implements ProxySocket {
  final SecureSocket socket;

  ProxySocketSecure(this.socket);
  
  ProxyAddress get address => ProxyAddress(host: socket.remoteAddress.host, port: socket.remotePort);
  
  @override
  Future<void> close() => socket.close();
  
  @override
  Future<void> destroy() async => socket.destroy();
  
  @override
  Future<void> write(String data) async => socket.write(data);
  
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
