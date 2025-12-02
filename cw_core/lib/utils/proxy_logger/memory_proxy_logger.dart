import 'dart:typed_data';

import 'package:cw_core/utils/proxy_logger/abstract.dart';
import 'package:http/http.dart' as very_insecure_http_do_not_use;

class MemoryProxyLoggerEntry {
  MemoryProxyLoggerEntry({
    required this.trace,
    required this.uri,
    required this.body,
    required this.network,
    required this.method,
    required this.response,
    required this.error,
  }) : time = DateTime.now();

  final StackTrace trace;
  final Uri? uri;
  final Uint8List body;
  final RequestNetwork network;
  final very_insecure_http_do_not_use.Response? response;
  final RequestMethod method;
  final String? error;
  final DateTime time;
  @override
  String toString() => """MemoryProxyLoggerEntry(
  uri: $uri,
  body: $body,
  network: $network,
  method: $method,
  response:
    code: ${response?.statusCode},
    headers: ${response?.headers},
    body: ${response?.body},
  error: $error,
  time: $time,
  trace: ${trace}
);""";
}

class MemoryProxyLogger implements ProxyLogger {
  static List<MemoryProxyLoggerEntry> logs = [];
  @override
  void log({
    required Uri? uri,
    required RequestMethod method,
    required Uint8List body,
    required very_insecure_http_do_not_use.Response? response,
    required RequestNetwork network, 
    required String? error,
  }) {
    final trace = StackTrace.current;
    logs.add(MemoryProxyLoggerEntry(
      method: method,
      trace: trace,
      uri: uri,
      body: body,
      network: network,
      response: response,
      error: error,),
    );
  }
}