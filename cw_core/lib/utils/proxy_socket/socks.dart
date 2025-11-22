import 'dart:async';
import 'dart:typed_data';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'package:socks_socket/socks_socket.dart';

class ProxySocketSocks implements ProxySocket {
  final SOCKSSocket socket;
  bool isClosed = false;
  ProxySocketSocks(this.socket);
  
  @override
  ProxyAddress get address => ProxyAddress(host: socket.proxyHost, port: socket.proxyPort);
  
  @override
  Future<void> close() async {
    try {
      if (isClosed) return;
      isClosed = true;
      await socket.close();
    } catch (e) {
      printV("ProxySocketSocks: close: $e");
      return;
    }
  }
  
  @override
  void destroy() => close();
  
  @override
  void write(String data) {
    try {
      if (isClosed) {
        printV("ProxySocketSocks: write: socket is closed");
        return;
      }
      socket.write(data);
    } catch (e) {
      printV("ProxySocketSocks: write: $e");
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

