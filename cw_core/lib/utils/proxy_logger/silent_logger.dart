import 'dart:typed_data';

import 'package:cw_core/utils/proxy_logger/abstract.dart';
import 'package:http/http.dart' as very_insecure_http_do_not_use;

// we are not doing anything
class SilentProxyLogger implements ProxyLogger {
  @override
  void log({
    required Uri? uri,
    required RequestMethod method,
    required Uint8List body,
    required very_insecure_http_do_not_use.Response? response,
    required RequestNetwork network, 
    required String? error,
  }) {}
}