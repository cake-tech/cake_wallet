import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';

class ProxySocketSecure implements ProxySocket {
  final SecureSocket socket;

  bool isClosed = false;

  ProxySocketSecure(this.socket);
  
  ProxyAddress get address => ProxyAddress(host: socket.remoteAddress.host, port: socket.remotePort);
  
  @override
  Future<void> close() async {
    try {
      if (isClosed) return;
      isClosed = true;
      return socket.close();
    } catch (e) {
      printV("ProxySocketSecure: close: $e");
      return;
    }
  }
  
  @override
  void destroy() async {
    try {
    if (isClosed) return;
      isClosed = true;
      socket.destroy();
    } catch (e) {
      printV("ProxySocketSecure: destroy: $e");
      return;
    }
  }
  
  @override
  void write(String data) {
    try {
      if (isClosed) {
        printV("ProxySocketSecure: write: socket is closed");
        return;
      }
      socket.write(data);
    } catch (e) {
      printV("ProxySocketSecure: write: $e");
      return;
    }
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
