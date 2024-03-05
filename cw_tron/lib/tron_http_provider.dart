import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:on_chain/tron/tron.dart';

class TronHTTPProvider implements TronServiceProvider {
  TronHTTPProvider(
      {required this.url,
      http.Client? client,
      this.defaultRequestTimeout = const Duration(seconds: 30)})
      : client = client ?? http.Client();
  @override
  final String url;
  final http.Client client;
  final Duration defaultRequestTimeout;

  @override
  Future<Map<String, dynamic>> get(TronRequestDetails params,
      [Duration? timeout]) async {
    final response = await client.get(Uri.parse(params.url(url)), headers: {
      'Content-Type': 'application/json'
    }).timeout(timeout ?? defaultRequestTimeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data;
  }

  @override
  Future<Map<String, dynamic>> post(TronRequestDetails params,
      [Duration? timeout]) async {
    final response = await client
        .post(Uri.parse(params.url(url)),
            headers: {'Content-Type': 'application/json'},
            body: params.toRequestBody())
        .timeout(timeout ?? defaultRequestTimeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data;
  }
}
