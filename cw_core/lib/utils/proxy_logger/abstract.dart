import 'dart:typed_data';
import 'package:http/http.dart' as very_insecure_http_do_not_use;

enum RequestNetwork {
  clearnet,
  tor,
}

enum RequestMethod {
  get,
  post,
  put,
  delete,
  
  newHttpClient,
  newHttpIOClient,
  newProxySocket,
}

abstract class ProxyLogger {
  void log({
    required Uri? uri,
    required RequestMethod method,
    required Uint8List body,
    required very_insecure_http_do_not_use.Response? response,
    required RequestNetwork network, 
    required String? error,
  });
}