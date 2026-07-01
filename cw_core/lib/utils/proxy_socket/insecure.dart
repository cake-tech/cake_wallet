
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

class ProxySocketInsecure implements ProxySocket {
  final Socket socket;

  ProxySocketInsecure(this.socket);
  
  bool isClosed = false;

  ProxyAddress get address => ProxyAddress(host: socket.remoteAddress.host, port: socket.remotePort);
  
  @override
  Future<void> close() async {
    try {
    if (isClosed) return;
      isClosed = true;
      return socket.close();
    } catch (e) {
      printV("ProxySocketInsecure: close: $e");
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
      printV("ProxySocketInsecure: destroy: $e");
      return;
    }
  }
  
  @override
  void write(String data) {
    try {
      if (isClosed) {
        printV("ProxySocketInsecure: write: socket is closed");
        return;
      }
      socket.write(data);
    } catch (e) {
      printV("ProxySocketInsecure: write: $e");
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