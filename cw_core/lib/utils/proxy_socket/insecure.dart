
import 'package:cw_core/utils/proxy_socket/abstract.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

class ProxySocketInsecure implements ProxySocket {
  final Socket socket;

  ProxySocketInsecure(this.socket);
  
  ProxyAddress get address => ProxyAddress(host: socket.remoteAddress.host, port: socket.remotePort);
  
  @override
  Future<void> close() => socket.close();
  
  @override
  void destroy() => socket.destroy();
  
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