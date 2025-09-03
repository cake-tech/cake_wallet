
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

class ProxySocketInsecure implements ProxySocket {
  final Socket socket;

  ProxySocketInsecure(this.socket);
  
  bool _isClosed = false;

  ProxyAddress get address => ProxyAddress(host: socket.remoteAddress.host, port: socket.remotePort);
  
  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    return socket.close();
  }
  
  @override
  void destroy() async {
    if (_isClosed) return;
    _isClosed = true;
    socket.destroy();
  }
  
  @override
  void write(String data) {
    if (_isClosed) {
      printV("ProxySocketInsecure: write: socket is closed");
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