import 'package:http/http.dart';
import 'package:on_chain/solana/solana.dart';

class SolanaRPCHTTPService implements SolanaServiceProvider {
  SolanaRPCHTTPService(
      {required this.url, Client? client, this.defaultRequestTimeout = const Duration(seconds: 30)})
      : client = client ?? Client();

  final String url;
  final Client client;
  final Duration defaultRequestTimeout;

  @override
  Future<SolanaServiceResponse<T>> doRequest<T>(SolanaRequestDetails params,
      {Duration? timeout}) async {
    if (!params.type.isPostRequest) {
      final response = await client.get(
        params.toUri(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout ?? defaultRequestTimeout);
      return params.toResponse(response.bodyBytes, response.statusCode);
    }

    final response = await client
        .post(
          params.toUri(url),
          headers: {'Content-Type': 'application/json'},
          body: params.body(),
        )
        .timeout(timeout ?? defaultRequestTimeout);
    return params.toResponse(response.bodyBytes, response.statusCode);
  }
}
