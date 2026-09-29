import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_api.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_configuration.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_currency_mapper.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_provider_preferences.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as very_insecure_http_do_not_use;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences storage;
  late PegarouteProviderPreferences preferences;
  late Map<String, dynamic> quote;
  late PegaRouteExchangeProvider provider;
  var gets = 0;
  var responseStatus = 200;
  Limits? quoteLimits;
  Future<void> Function()? beforeResponse;

  Future<double> rate({String amount = '1'}) {
    quoteLimits = null;
    return provider.fetchRateExact(from: CryptoCurrency.eth, to: CryptoCurrency.usdc,
        amount: amount, onLimits: (value) => quoteLimits = value);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await SharedPreferences.getInstance();
    preferences = PegarouteProviderPreferences(storage);
    gets = 0;
    responseStatus = 200;
    quoteLimits = null;
    beforeResponse = null;
    quote = jsonDecode(File('test/exchange/fixtures/pegaroute/quote.json').readAsStringSync())
        as Map<String, dynamic>;
    quote['expiresAt'] = '2099-01-01T00:00:00.000Z';
    final template = Map<String, dynamic>.from(quote['routes'][0] as Map);
    // Deliberately unsorted: selection must use the enabled route's output.
    quote['routes'] = [
      {...template, 'provider': 'instaswap', 'expectedOutput': '12', 'minAmount': '0.005'},
      {...template, 'provider': 'thorchain', 'expectedOutput': '10', 'minAmount': '0.002'},
      {...template, 'provider': 'openocean', 'expectedOutput': '11', 'minAmount': '0.001'},
    ];
    provider = PegaRouteExchangeProvider(
      providerPreferences: preferences,
      apiClient: PegarouteApiClient(
        configuration: const PegarouteConfiguration(baseUrl: 'https://fixture.invalid'),
        get: (uri, headers) async {
          if (uri.path == '/chains') return very_insecure_http_do_not_use.Response(jsonEncode({
            'chains': [{'id': 'ETH', 'name': 'Ethereum', 'chainId': 1}]}), 200);
          if (uri.path == '/tokens') return very_insecure_http_do_not_use.Response(jsonEncode({
            'chain': 'ETH', 'tokens': [{'id': 'ETH', 'symbol': 'ETH'},
              {'id': const PegarouteCurrencyMapper().map(CryptoCurrency.usdc).token, 'symbol': 'USDC'}]}), 200);
          expect(uri.path, '/quote');
          expect(headers, isEmpty);
          gets++;
          await beforeResponse?.call();
          return very_insecure_http_do_not_use.Response(jsonEncode(quote), responseStatus);
        },
        post: (_, __, ___) async => throw StateError('Quote discovery must never create an order'),
      ),
    );
  });

  test('provider choices persist independently and survive reload', () async {
    expect(preferences.states.values, everyElement(true));
    await preferences.setEnabled('instaswap', false);
    await preferences.setEnabled('maya', false);
    final restored = PegarouteProviderPreferences(storage);
    expect(restored.isEnabled('instaswap'), false);
    expect(restored.isEnabled('maya'), false);
    expect(restored.isEnabled('openocean'), true);
    expect(restored.isEnabled('thorchain'), true);
    expect(restored.isEnabled('unknown'), false);
    await expectLater(restored.setEnabled('unknown', true), throwsArgumentError);
  });

  test('malformed preferences do not re-enable excluded providers', () async {
    await storage.setString(PreferencesKey.pegarouteProviderStatesKey, 'broken');
    expect(PegarouteProviderPreferences(storage).states.values, everyElement(false));
    await storage.setString(PreferencesKey.pegarouteProviderStatesKey,
        jsonEncode({'instaswap': 'true', 'maya': false}));
    final restored = PegarouteProviderPreferences(storage);
    expect(restored.isEnabled('instaswap'), false);
    expect(restored.isEnabled('maya'), false);
    expect(restored.isEnabled('thorchain'), true);
  });

  test('discovery selects the highest enabled quote and filters limits', () async {
    expect(await rate(), 12);
    await preferences.setEnabled('instaswap', false);
    expect(await rate(), 11);
    await preferences.setEnabled('openocean', false);
    expect(await rate(), 10);
    expect(quoteLimits!.min, 0.002);
    final beforeLimits = gets;
    final limits = await provider.fetchLimits(
        from: CryptoCurrency.eth, to: CryptoCurrency.usdc, isFixedRateMode: false);
    expect(limits!.min, 0);
    expect(gets, beforeLimits);
    await preferences.setEnabled('thorchain', false);
    expect(await rate(), 0);
    expect(quoteLimits, isNull);
    await preferences.setEnabled('maya', false);
    expect(await provider.fetchLimits(
        from: CryptoCurrency.eth, to: CryptoCurrency.usdc, isFixedRateMode: false), isNull);
    final before = gets;
    expect(await rate(), 0);
    expect(gets, before);
  });

  test('decentralized provider includes Instaswap and preserves explicit disable on reload', () async {
    expect(provider.description.isCentralized, false);
    expect(await rate(), 12);
    expect(preferences.isEnabled('instaswap'), true);
    await preferences.setEnabled('instaswap', false);
    expect(await rate(), 11);
    expect(PegarouteProviderPreferences(storage).isEnabled('instaswap'), false);
  });

  test('quote limits include enabled Instaswap', () async {
    await preferences.setEnabled('openocean', false);
    await preferences.setEnabled('thorchain', false);
    expect(await rate(), 12);
    expect(quoteLimits!.min, 0.005);
    await preferences.setEnabled('instaswap', false);
    expect(await rate(), 0);
    expect(quoteLimits, isNull);
  });

  test('a provider disabled while HTTP is pending cannot supply the returned rate', () async {
    final waiting = Completer<void>();
    final entered = Completer<void>();
    beforeResponse = () {
      entered.complete();
      return waiting.future;
    };
    final pending = rate();
    await entered.future;
    await preferences.setEnabled('instaswap', false);
    waiting.complete();
    expect(await pending, 11);
  });

  test('an executable route does not inherit a rejected route minimum', () async {
    final route = Map<String, dynamic>.from((quote['routes'] as List).last as Map);
    quote['routes'] = [{...route, 'minAmount': null}];
    quote['warnings'] = [{'provider': 'instaswap', 'code': 'AMOUNT_TOO_LOW',
      'message': 'Below minimum', 'userMessage': 'Minimum: 0.0063 ETH.'}];
    expect(await rate(amount: '0.001'), greaterThan(0));
    expect(quoteLimits!.min, 0);
  });

  test('rejected routes report the lowest supported minimum', () async {
    expect(await rate(amount: '0.0001'), 0);
    expect(quoteLimits!.min, 0.001);
    await preferences.setEnabled('openocean', false);
    expect(await rate(amount: '0.0001'), 0);
    expect(quoteLimits!.min, 0.002);
  });

  test('empty routes expose the current warning minimum and clear it on an outage', () async {
    quote['routes'] = [];
    quote['warnings'] = [
      {'provider': 'instaswap', 'code': 'AMOUNT_TOO_LOW',
        'message': 'Below minimum', 'userMessage': 'Minimum: 0.0063 ETH.'},
      {'provider': 'maya', 'code': 'CHAIN_HALTED',
        'message': 'Chain halted', 'userMessage': 'Chain halted'},
    ];
    expect(await rate(amount: '0.001'), 0);
    expect(quoteLimits!.min, 0.0063);
    quote['warnings'] = [];
    expect(await rate(amount: '0.001'), 0);
    expect(quoteLimits, isNull);
  });

  for (final status in [200, 400]) {
    test('a disabled provider cannot supply a minimum from HTTP $status', () async {
      final error = {'provider': 'instaswap', 'code': 'AMOUNT_TOO_LOW',
        'message': 'Below minimum', 'userMessage': 'Minimum: 0.0063 ETH.', 'retryable': false};
      if (status == 400) {
        responseStatus = 400;
        quote = {'error': error};
      } else {
        quote['routes'] = [];
        quote['warnings'] = [error];
      }
      expect(await rate(amount: '0.001'), 0);
      expect(quoteLimits!.min, 0.0063);
      final waiting = Completer<void>();
      final entered = Completer<void>();
      beforeResponse = () { entered.complete(); return waiting.future; };
      final pending = rate(amount: '0.001');
      await entered.future;
      await preferences.setEnabled('instaswap', false);
      waiting.complete();
      expect(await pending, 0);
      expect(quoteLimits, isNull);
    });
  }

  test('receive-amount requests return no rate without network access', () async {
    final offline = PegaRouteExchangeProvider(
      configuration: const PegarouteConfiguration(baseUrl: 'https://fixture.invalid'),
      request: (_, __, ___, ____) async => fail('Receive requests must not use the network'),
    );
    expect(offline.supportsFixedRate, isFalse);
    expect(await offline.fetchRate(from: CryptoCurrency.eth, to: CryptoCurrency.usdc,
        amount: 1, isFixedRateMode: false, isReceiveAmount: true), 0);
    expect(await offline.fetchRate(from: CryptoCurrency.eth, to: CryptoCurrency.usdc,
        amount: 1, isFixedRateMode: true, isReceiveAmount: false), 0);
    // The legacy forward-rate entry point remains available.
    expect(await provider.fetchRate(from: CryptoCurrency.eth, to: CryptoCurrency.usdc,
        amount: 1, isFixedRateMode: false, isReceiveAmount: false), 12);
  });
}
