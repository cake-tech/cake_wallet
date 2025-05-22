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
}
