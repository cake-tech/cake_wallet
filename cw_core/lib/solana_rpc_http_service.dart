import 'dart:convert';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:on_chain/solana/solana.dart';

class SolanaRPCHTTPService implements SolanaJSONRPCService {
  SolanaRPCHTTPService(
      {required this.url,
      this.defaultRequestTimeout = const Duration(seconds: 30)});
  @override
  final String url;
  final Duration defaultRequestTimeout;

  final client = ProxyWrapper().getHttpIOClient();

  @override
  Future<Map<String, dynamic>> call(SolanaRequestDetails params,
      [Duration? timeout]) async {
    final response = await client.post(
      Uri.parse(url),
      body: params.toRequestBody(),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(timeout ?? defaultRequestTimeout);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data;
  }

  Future<Map<String, dynamic>> call(SolanaRequestDetails params,
      [Duration? timeout]) async {
    final response = await ProxyWrapper().post(
      clearnetUri: Uri.parse(url),
      body: json.encode(params.toJson()),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(timeout ?? defaultRequestTimeout);
    final responseString = await response.transform(utf8.decoder).join();
    final data = json.decode(responseString) as Map<String, dynamic>;
    return data;
  }
}
