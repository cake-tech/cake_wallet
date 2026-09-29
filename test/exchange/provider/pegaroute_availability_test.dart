import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_api.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_configuration.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';
// This import creates synthetic responses only. The tests do not open sockets.
import 'package:http/http.dart' as very_insecure_http_do_not_use;

Map<String, dynamic> quoteFixture() {
  final value = jsonDecode(File('test/exchange/fixtures/pegaroute/quote.json').readAsStringSync())
      as Map<String, dynamic>;
  value['expiresAt'] = '2099-01-01T00:00:00Z';
  return value;
}

void main() {
  const configuration = PegarouteConfiguration(baseUrl: 'https://offline.invalid');
  const usdc = 'USDC-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
  for (final path in ['/chains', '/tokens', '/quote']) {
    for (final hangs in [false, true]) {
      test('$path ${hangs ? "timeout" : "outage"} permits a later quote on the same provider', () async {
        var unavailable = true;
        var posts = 0;
        final waiting = Completer<very_insecure_http_do_not_use.Response>();
        final client = PegarouteApiClient(configuration: configuration,
            readTimeout: const Duration(milliseconds: 20),
            post: (_, __, ___) async {
              posts++;
              throw StateError('No POST is permitted in quote tests');
            },
            get: (uri, headers) async {
              if (unavailable && uri.path == path) {
                if (hangs) return waiting.future;
                return very_insecure_http_do_not_use.Response(jsonEncode({'error': {
                  'code': 'PROVIDER_UNAVAILABLE', 'message': 'Offline',
                  'userMessage': 'Offline', 'retryable': true,
                }}), 502);
              }
              final Object body;
              if (uri.path == '/chains') {
                body = {'chains': [{'id': 'ETH', 'name': 'Ethereum', 'chainId': 1}]};
              } else if (uri.path == '/tokens') {
                body = {'chain': 'ETH', 'tokens': [
                  {'id': 'ETH', 'symbol': 'ETH'}, {'id': usdc, 'symbol': 'USDC'}]};
              } else {
                body = quoteFixture();
              }
              return very_insecure_http_do_not_use.Response(jsonEncode(body), 200);
            });
        final provider = PegaRouteExchangeProvider(apiClient: client);
        Future<double> rate() => provider.fetchRateExact(from: CryptoCurrency.eth,
            to: CryptoCurrency.usdc, amount: '0.01').timeout(const Duration(seconds: 1));
        expect(await rate(), 0);
        expect(provider.isAvailable, true); // An outage does not disable configured providers.
        unavailable = false;
        expect(await rate(), greaterThan(0));
        if (hangs) waiting.complete(very_insecure_http_do_not_use.Response('{}', 502));
        expect(posts, 0);
      });
    }
  }

  test('status reads time out without a POST or automatic retry', () async {
    var reads = 0;
    final waiting = Completer<very_insecure_http_do_not_use.Response>();
    final client = PegarouteApiClient(configuration: configuration,
        readTimeout: const Duration(milliseconds: 20), get: (_, __) {
          reads++;
          return waiting.future;
        }, post: (_, __, ___) => throw StateError('Unexpected POST'));
    await expectLater(client.status('offline-order'), throwsA(isA<TimeoutException>()));
    expect(reads, 1);
    waiting.complete(very_insecure_http_do_not_use.Response('{}', 502));
  });
}
