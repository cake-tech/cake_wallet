import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';

class ProxySocketSecure implements ProxySocket {
  final SecureSocket socket;

  bool _isClosed = false;

  ProxySocketSecure(this.socket);
  
  ProxyAddress get address => ProxyAddress(host: socket.remoteAddress.host, port: socket.remotePort);
  
  @override
  Future<void> close() {
    _isClosed = true;
    return socket.close();
  }
  
  @override
  void destroy() {
    _isClosed = true;
    socket.destroy();
  }
  
  @override
  void write(String data) {
    if (_isClosed) {
      printV("ProxySocketSecure: write: socket is closed");
      return;
    }
    socket.write(data);
  }
  
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
