import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_api.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_configuration.dart';
import 'package:http/http.dart' as very_insecure_http_do_not_use;

// Reused final-reference wire/transport scenarios only. Successful decoding is
// not funding eligibility; real provider/store/wallet callers test that seam.
String _fixture(String name) => File('test/exchange/fixtures/pegaroute/$name').readAsStringSync();
Map<String, dynamic> _amount() => {'display': '1', 'baseUnits': '1'};
const _unsupportedFamilies = {'cosmos', 'sui', 'xrp', 'near', 'hypercore', 'cardano'};

List<Map<String, dynamic>> _executionVariants() => [
      {
        'family': 'evm',
        'mode': 'contract-call',
        'chainId': 1,
        'to': '0x0000000000000000000000000000000000000001',
        'data': '0xabcdef',
        'value': null,
        'gasLimit': null,
        'memo': null,
        'approval': null,
        'transferAmount': null,
      },
      {
        'family': 'evm',
        'mode': 'native-transfer',
        'chainId': 1,
        'to': '0x0000000000000000000000000000000000000001',
        'data': null,
        'value': _amount(),
        'gasLimit': null,
        'memo': null,
        'approval': null,
        'transferAmount': null,
      },
      {
        'family': 'evm',
        'mode': 'erc20-transfer',
        'chainId': 1,
        'to': '0x0000000000000000000000000000000000000001',
        'data': null,
        'value': null,
        'gasLimit': null,
        'memo': null,
        'approval': null,
        'transferAmount': _amount(),
      },
      {
        'family': 'utxo',
        'mode': 'payment-with-memo',
        'to': 'bc1qfixture',
        'amount': _amount(),
        'memo': null,
        'gasRate': null,
      },
      {
        'family': 'cosmos',
        'mode': 'bank-send',
        'to': 'cosmos1fixture',
        'amount': _amount(),
        'memo': null,
      },
      {
        'family': 'cosmos',
        'mode': 'msg-deposit',
        'to': 'cosmos1fixture',
        'amount': _amount(),
        'memo': null,
        'asset': 'THOR.RUNE',
        'assetDecimals': 8,
      },
      {
        'family': 'solana',
        'mode': 'serialized-tx',
        'encoding': 'base58',
        'serializedTransaction': '3MN',
        'minOut': null
      },
      {'family': 'sui', 'mode': 'serialized-tx', 'serializedTransaction': 'dHh4', 'minOut': null},
      ...['solana', 'sui', 'xrp', 'tron', 'near', 'hypercore', 'cardano'].map(
        (family) => <String, dynamic>{
          'family': family,
          'mode': 'deposit-transfer',
          'to': 'deposit-destination',
          'amount': _amount(),
          'memo': null,
        },
      ),
      {
        'family': 'other',
        'mode': 'deposit-transfer',
        'chain': 'APTOS',
        'to': 'deposit-destination',
        'amount': _amount(),
        'memo': null,
      },
    ];

void main() {
  test('validates full origins and only permits loopback HTTP', () {
    expect(PegarouteConfiguration(baseUrl: 'http://localhost:4000').isValid, isTrue);
    expect(PegarouteConfiguration(baseUrl: 'http://127.42.0.9:4000').isValid, isTrue);
    expect(PegarouteConfiguration(baseUrl: 'https://api.example.test:443/').isValid, isTrue);
    expect(PegarouteConfiguration(baseUrl: 'http://10.0.2.2:4000').isValid, isFalse);
    expect(PegarouteConfiguration(baseUrl: 'https://example.test/api').isValid, isFalse);
    expect(PegarouteConfiguration(baseUrl: 'https://user:pass@example.test').isValid, isFalse);
    expect(PegarouteConfiguration(baseUrl: 'https://example.test?x=1').isValid, isFalse);
  });

  test('decodes quote and swap fixtures with exact execution fields', () {
    final quote = PegarouteQuoteResponse.fromJson(json.decode(_fixture('quote.json')));
    expect(quote.routes.single.provider, 'instaswap');
    expect(quote.routes.single.subprovider, 'partner-fixture');

    final swap = PegarouteSwapResponse.fromJson(json.decode(_fixture('swap.json')));
    expect(swap.execution.family, 'evm');
    expect(swap.execution.mode, 'native-transfer');
    expect(swap.execution.value!.baseUnits, '1');
    expect(swap.provider.instaswapSwapLite!.txid, 'provider-reference-fixture');
  });

  test('preserves string private routes and treats an omitted value as false', () {
    final value = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    final route = (value['routes'] as List).single as Map<String, dynamic>;
    route['private'] = 'private-fixture';
    expect(
      PegarouteQuoteResponse.fromJson(value).routes.single.privateValue!.value,
      'private-fixture',
    );

    route.remove('private');
    expect(PegarouteQuoteResponse.fromJson(value).routes.single.privateValue, isNull);
  });

  test('accepts additive response metadata and omitted optional provider details', () {
    final quote = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    (quote['routes'] as List).single
      ..remove('subprovider')
      ..remove('private')
      ..['futureLabel'] = {'name': 'informational'};
    expect(PegarouteQuoteResponse.fromJson(quote).routes.single.subprovider, isNull);

    final swap = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    swap['futureInfo'] = ['informational'];
    (swap['route'] as Map)
      ..remove('subprovider')
      ..remove('private')
      ..['futureLabel'] = 'informational';
    (swap['provider'] as Map).remove('details');
    final decoded = PegarouteSwapResponse.fromJson(swap);
    expect(decoded.provider.details, isNull);
    expect(decoded.route.subprovider, isNull);
    expect(decoded.execution.value!.baseUnits, '1');

    (swap['execution'] as Map)['futureOperation'] = 'not supported';
    expect(() => PegarouteSwapResponse.fromJson(swap), throwsA(isA<PegarouteCodecException>()));
  });

  test('keeps required route and execution fields required when metadata is optional', () {
    for (final field in ['provider', 'expectedOutput', 'fees', 'estimatedTimeSeconds']) {
      final swap = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
      (swap['route'] as Map).remove(field);
      expect(() => PegarouteSwapResponse.fromJson(swap), throwsA(isA<PegarouteCodecException>()),
          reason: field);
    }
    for (final field in ['family', 'mode', 'to', 'chainId', 'value', 'data']) {
      final swap = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
      (swap['execution'] as Map).remove(field);
      expect(() => PegarouteSwapResponse.fromJson(swap), throwsA(isA<PegarouteCodecException>()),
          reason: field);
    }
  });

  test('freezes quote route maps, lists, and provider detail maps', () {
    final quoteValue = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    final quote = PegarouteQuoteResponse.fromJson(quoteValue);
    (quoteValue['routes'] as List).single['expectedOutput'] = '0.01';
    expect(quote.routes.single.expectedOutput, '0.99');
    expect(() => quote.routes.add(quote.routes.single), throwsA(isA<UnsupportedError>()));

    final feeValue = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    (feeValue['routes'] as List).single['resolvedFee'] = {'feeBps': 1};
    final feeQuote = PegarouteQuoteResponse.fromJson(feeValue);
    expect(
      () => feeQuote.routes.single.resolvedFee!['feeBps'] = 2,
      throwsA(isA<UnsupportedError>()),
    );

    final provider = PegarouteProviderInfo.fromJson(json.decode(_fixture('swap.json'))['provider']);
    expect(
      () => (provider.details as Map<String, dynamic>)['instaswapSwapLite'] = <String, dynamic>{},
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('direct route constructors copy mutable inputs before retaining them', () {
    final fields = {'provider'};
    final nested = [1];
    final fees = <String, dynamic>{'feeBps': 1, 'nested': nested};
    final dexes = [const PegarouteOpenOceanDex(dexId: 1, dexCode: 'fixture')];
    final route = PegarouteRoute(provider: 'openocean', expectedOutput: '1',
        resolvedFee: fees, presentFields: fields, openOceanRoute: PegarouteOpenOceanRoute(dexes: dexes));
    final provider = PegarouteProviderInfo(name: 'openocean', details: {'nested': nested});
    fields.clear();
    fees.clear();
    nested.clear();
    dexes.clear();
    expect(route.presentFields, {'provider'});
    expect(route.resolvedFee, {'feeBps': 1, 'nested': [1]});
    expect(route.openOceanRoute!.dexes!.single.dexId, 1);
    expect(provider.details, {'nested': [1]});
    expect(() => route.presentFields.clear(), throwsUnsupportedError);
    expect(() => route.openOceanRoute!.dexes!.clear(), throwsUnsupportedError);
    expect(() => ((provider.details as Map)['nested'] as List).clear(), throwsUnsupportedError);
  });

  test('Solana serialized execution requires and preserves its encoding label', () {
    final value = _executionVariants().firstWhere((value) => value['family'] == 'solana');
    final execution = PegarouteExecution.fromJson(value);
    expect(execution.toJson()['encoding'], 'base58');
    expect(execution.toJson()['serializedTransaction'], value['serializedTransaction']);
  });

  test('Solana serialized execution rejects missing and invalid encoding labels', () {
    final value = _executionVariants().firstWhere((value) => value['family'] == 'solana');
    value.remove('encoding');
    expect(() => PegarouteExecution.fromJson(value), throwsA(isA<PegarouteCodecException>()));
    for (final label in [null, '', 'BASE64', 'base64 ', 'unknown', 1, true]) {
      value['encoding'] = label;
      expect(() => PegarouteExecution.fromJson(value), throwsA(isA<PegarouteCodecException>()));
    }
  });

  test('encoding is forbidden on every non-Solana-serialized API shape', () {
    for (final value in _executionVariants()) {
      if (value['family'] == 'solana' && value['mode'] == 'serialized-tx') continue;
      for (final label in [null, 'base64']) {
        value['encoding'] = label;
        expect(() => PegarouteExecution.fromJson(value), throwsA(isA<PegarouteCodecException>()));
      }
    }
  });

  test('decodes order status and refund evidence', () {
    final status = PegarouteStatusResponse.fromJson(json.decode(_fixture('status_refund.json')));
    expect(status.internalStatus, 'refunded');
    expect(status.input.refundAddress, isNotNull);
    expect(status.refund, isNull);
    expect(status.output.txHash, 'output-hash-fixture');
  });

  test('unused status metadata does not replace order or refund fields', () {
    final value = json.decode(_fixture('status_refund.json')) as Map<String, dynamic>;
    const unused = ['fees', 'timestamps', 'affiliateFeeBreakdown', 'error', 'streamingProgress'];
    for (final field in unused) { value.remove(field); }
    expect(PegarouteStatusResponse.fromJson(value).internalStatus, 'refunded');
    for (final field in unused) { value[field] = {'futureMetadata': true}; }
    final status = PegarouteStatusResponse.fromJson(value);
    expect(status.internalStatus, 'refunded');
    expect(status.refund, isNull);
    expect(status.output.txHash, 'output-hash-fixture');
    value.remove('refund');
    expect(() => PegarouteStatusResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
  });

  test('errors retain public codes but discard retry and diagnostic metadata', () {
    final error = PegarouteApiError.fromJson(429, {
      'error': {
        'code': 'RATE_LIMITED',
        'message': 'retry later',
        'userMessage': 'Please retry later',
        'retryable': true,
        'retryAfterSeconds': 3,
        'provider': 'fixture-provider',
        'details': {'future': true},
      },
    });
    expect(error.code, 'RATE_LIMITED');
    expect(error.httpStatus, 429);
    expect(error.minAmount, isNull);
    expect(error.toString(), isNot(contains('retry later')));
    expect(error.userMessage, 'Pegaroute RATE_LIMITED');
  });

  test('uses identical normalized sender and refund intent in requests', () {
    final quote = PegarouteQuoteRequest(fromChain: 'ETH', fromToken: 'ETH',
        toChain: 'BTC', toToken: 'BTC', amount: '1',
        destinationAddress: ' destination ', senderAddress: ' sender ', refundAddress: ' refund ');
    final swap = PegarouteSwapRequest(fromChain: 'ETH', fromToken: 'ETH',
        toChain: 'BTC', toToken: 'BTC', amount: '1',
        destinationAddress: ' destination ', senderAddress: ' sender ', refundAddress: ' refund ');
    final expected = {'fromChain': 'ETH', 'fromToken': 'ETH', 'toChain': 'BTC', 'toToken': 'BTC',
      'amount': '1', 'destinationAddress': 'destination', 'senderAddress': 'sender', 'refundAddress': 'refund'};
    expect(quote.toQuery(), expected);
    expect(swap.toJson(), expected);
  });

  test('public-only swaps omit the retired private JSON body field', () {
    final request = PegarouteSwapRequest(
      fromChain: 'ETH',
      fromToken: 'ETH',
      toChain: 'BTC',
      toToken: 'BTC',
      amount: '1',
      destinationAddress: 'destination',
      senderAddress: 'sender',
    );
    expect(request.toJson().keys, isNot(contains('private')));
    expect(request.toJson().keys, isNot(contains('slippageTolerance')));
    expect(request.toJson().keys, isNot(contains('streaming')));
  });

  test('decodes canonical private modes and preserves the warning audit trail', () {
    final value = json.decode(_fixture('quote_private_zk.json')) as Map<String, dynamic>;
    final quote = PegarouteQuoteResponse.fromJson(value);
    expect(quote.routes.single.privateValue!.value, 'zk');
    expect(quote.warnings.map((warning) => warning.provider), ['thorchain', 'maya', 'openocean']);
    final route = (value['routes'] as List).single as Map<String, dynamic>;
    for (final mode in [false, true, 'zk', 'future-mode', 'false', 'x' * 64]) {
      route['private'] = mode;
      final decoded = PegarouteQuoteResponse.fromJson(value).routes.single.privateValue!;
      expect(decoded.value, mode);
      expect(decoded.isEnabled, mode != false);
    }
    for (final mode in [null, '', '   ', 'x' * 65, 0, [], {}]) {
      route['private'] = mode;
      expect(() => PegarouteQuoteResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
    }
  });

  test('requests only public quotes and rejects a private route before POST', () async {
    final client = PegarouteApiClient(
      configuration: const PegarouteConfiguration(baseUrl: 'https://example.test'),
      get: (uri, headers) async {
        expect(uri.queryParameters.keys, isNot(contains('private')));
        expect(uri.queryParameters.keys, isNot(contains('integrationId')));
        expect(headers, isEmpty);
        return very_insecure_http_do_not_use.Response(_fixture('quote_private_zk.json'), 200);
      },
      post: (_, __, ___) async => fail('A private route must not reach POST'),
    );
    final quote = await client.quote(PegarouteQuoteRequest(fromChain: 'ETH', fromToken: 'ETH',
        toChain: 'BTC', toToken: 'BTC', amount: '1', senderAddress: 'sender', destinationAddress: 'payout'));
    expect(json.decode(quote.requestJson)['private'], false);
    final route = quote.response.routes.single;
    expect(route.privateValue!.isEnabled, true);
    expect(() => client.preflight(quote: quote, route: route,
        request: PegarouteSwapRequest(fromChain: 'ETH', fromToken: 'ETH', toChain: 'BTC', toToken: 'BTC',
          amount: '1', senderAddress: 'sender', destinationAddress: 'payout',
          quoteId: quote.response.quoteId, routeProvider: route.provider)),
        throwsA(isA<PegarouteCodecException>()));
  });

  test('quote refunds still require a sender', () {
    final request = PegarouteQuoteRequest(fromChain: 'ETH', fromToken: 'ETH',
        toChain: 'BTC', toToken: 'BTC', amount: '1', refundAddress: 'refund');
    expect(request.toQuery, throwsA(isA<PegarouteCodecException>()));
  });

  test('blank request fields cannot become omitted intent', () {
    for (final blank in ['', '   ']) {
      for (final create in <Object Function()>[
        () => PegarouteQuoteRequest(fromChain: blank, fromToken: 'ETH',
            toChain: 'BTC', toToken: 'BTC', amount: '1'),
        () => PegarouteQuoteRequest(fromChain: 'ETH', fromToken: 'ETH',
            toChain: 'BTC', toToken: 'BTC', amount: '1', senderAddress: 'sender', refundAddress: blank),
        () => PegarouteSwapRequest(fromChain: 'ETH', fromToken: 'ETH',
            toChain: 'BTC', toToken: 'BTC', amount: '1', destinationAddress: 'destination',
            senderAddress: 'sender', refundAddress: blank),
        () => PegarouteSwapRequest(fromChain: 'ETH', fromToken: 'ETH',
            toChain: 'BTC', toToken: 'BTC', amount: '1', destinationAddress: blank, senderAddress: 'sender'),
        () => PegarouteSwapRequest(fromChain: 'ETH', fromToken: 'ETH',
            toChain: 'BTC', toToken: 'BTC', amount: '1', destinationAddress: 'destination', senderAddress: blank),
      ]) {
        expect(create, throwsA(isA<PegarouteCodecException>()));
      }
    }
  });

  test('omits sender-equivalent refunds in direct request constructors', () {
    final quote = PegarouteQuoteRequest(
      fromChain: 'ETH',
      fromToken: 'ETH',
      toChain: 'BTC',
      toToken: 'BTC',
      amount: '1',
      senderAddress: ' sender ',
      refundAddress: 'sender',
    );
    final swap = PegarouteSwapRequest(
      fromChain: 'ETH',
      fromToken: 'ETH',
      toChain: 'BTC',
      toToken: 'BTC',
      amount: '1',
      destinationAddress: 'destination',
      senderAddress: ' sender ',
      refundAddress: 'sender',
    );
    expect(quote.senderAddress, 'sender');
    expect(quote.refundAddress, isNull);
    expect(swap.senderAddress, 'sender');
    expect(swap.refundAddress, isNull);

    final evm = PegarouteSwapRequest(
      fromChain: 'ETH',
      fromToken: 'ETH',
      toChain: 'BTC',
      toToken: 'BTC',
      amount: '1',
      destinationAddress: 'destination',
      senderAddress: '0xABCDEF0000000000000000000000000000000001',
      refundAddress: '0xabcdef0000000000000000000000000000000001',
    );
    expect(evm.refundAddress, isNull);

    final nonEvm = PegarouteSwapRequest(
      fromChain: 'SOL',
      fromToken: 'SOL',
      toChain: 'BTC',
      toToken: 'BTC',
      amount: '1',
      destinationAddress: 'destination',
      senderAddress: 'SolAddress',
      refundAddress: 'soladdress',
    );
    expect(nonEvm.refundAddress, 'soladdress');
  });

  test('injects transport without exposing credentials', () async {
    final calls = <String>[];
    final client = PegarouteApiClient(
      configuration: const PegarouteConfiguration(baseUrl: 'https://example.test'),
      get: (uri, headers) async {
        calls.add('${uri.path}?${uri.query}');
        expect(headers, isEmpty);
        return very_insecure_http_do_not_use.Response(_fixture('quote.json'), 200);
      },
    );
    final result = await client.quote(
      PegarouteQuoteRequest(
        fromChain: 'ETH',
        fromToken: 'ETH',
        toChain: 'BTC',
        toToken: 'BTC',
        amount: '1',
      ),
    );
    expect(result.response.quoteId, 'quote-fixture');
    expect(calls, ['/quote?fromChain=ETH&fromToken=ETH&toChain=BTC&toToken=BTC&amount=1']);
  });

  test('catalog reads keep exact IDs and reject invalid identity fields', () async {
    Map<String, dynamic> body = {'chains': [{'id': 'ETH'}, {'id': 'ETH'}]};
    final client = PegarouteApiClient(
      configuration: const PegarouteConfiguration(baseUrl: 'https://example.test'),
      get: (_, __) async => very_insecure_http_do_not_use.Response(json.encode(body), 200),
    );
    final chains = await client.chains();
    expect(chains, {'ETH'});
    expect(() => chains.add('BSC'), throwsUnsupportedError);
    const mint = 'USDC-EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
    body = {'chain': 'SOL', 'tokens': [{'id': mint, 'symbol': null}]};
    expect(await client.tokens('SOL'), {mint});
    await expectLater(client.tokens('ETH'), throwsA(isA<PegarouteCodecException>()));
    for (final item in [{}, {'id': ''}, {'id': 1}]) {
      body = {'chains': [item]};
      await expectLater(client.chains(), throwsA(isA<PegarouteCodecException>()));
      body = {'chain': 'ETH', 'tokens': [item]};
      await expectLater(client.tokens('ETH'), throwsA(isA<PegarouteCodecException>()));
    }
  });

  test('creation still requires the pending status before returning a result', () {
    final value = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    expect(PegarouteSwapResponse.fromJson(value).transactionId, isNotEmpty);
    for (final status in [null, '', 'completed', 'failed', 1]) {
      value['status'] = status;
      expect(() => PegarouteSwapResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
    }
  });

  test('rejects unknown execution modes', () {
    final value = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    (value['execution'] as Map<String, dynamic>)['mode'] = 'future-mode';
    expect(() => PegarouteSwapResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
  });

  test('rejects schema omissions instead of accepting partial routes', () {
    final value = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    final route = (value['routes'] as List).single as Map<String, dynamic>;
    route.remove('fees');
    expect(() => PegarouteQuoteResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
  });

  test('requires nullable contract fields while accepting explicit nulls', () {
    final quote = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    expect(PegarouteQuoteResponse.fromJson(quote), isA<PegarouteQuoteResponse>());
    final quoteRoute = (quote['routes'] as List).single as Map<String, dynamic>;
    quoteRoute.remove('memo');
    expect(() => PegarouteQuoteResponse.fromJson(quote), throwsA(isA<PegarouteCodecException>()));

    final swap = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    expect(PegarouteSwapResponse.fromJson(swap), isA<PegarouteSwapResponse>());
    final execution = swap['execution'] as Map<String, dynamic>;
    execution.remove('memo');
    expect(() => PegarouteSwapResponse.fromJson(swap), throwsA(isA<PegarouteCodecException>()));

    final provider = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    final providerMap = provider['provider'] as Map<String, dynamic>;
    providerMap['referenceId'] = null;
    expect(PegarouteSwapResponse.fromJson(provider), isA<PegarouteSwapResponse>());
    providerMap.remove('referenceId');
    expect(() => PegarouteSwapResponse.fromJson(provider), throwsA(isA<PegarouteCodecException>()));
  });

  test('accepts the compact route shape used by swap status responses', () {
    final value = json.decode(_fixture('status_refund.json')) as Map<String, dynamic>;
    final route = value['route'] as Map<String, dynamic>;
    route.remove('providerType');
    route.remove('expiry');
    route.remove('memo');
    route.remove('inboundAddress');
    route.remove('router');
    route.remove('gasRate');
    route.remove('minAmount');
    route.remove('resolvedFee');
    expect(PegarouteStatusResponse.fromJson(value).route.provider, 'instaswap');
  });

  test('rejects incompatible EVM execution fields', () {
    final value = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    final execution = value['execution'] as Map<String, dynamic>;
    execution['mode'] = 'contract-call';
    execution['data'] = '0xdeadbeef';
    execution['transferAmount'] = {'display': '1', 'baseUnits': '1'};
    expect(() => PegarouteSwapResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
  });

  test('requires calldata for contract-call execution', () {
    final value = json.decode(_fixture('swap.json')) as Map<String, dynamic>;
    final execution = value['execution'] as Map<String, dynamic>;
    execution['mode'] = 'contract-call';
    execution['data'] = null;
    expect(() => PegarouteSwapResponse.fromJson(value), throwsA(isA<PegarouteCodecException>()));
  });

  test('rejects invalid refund lifecycle values', () {
    expect(
      () => PegarouteRefund.fromJson({
        'status': 'sent',
        'chain': 'ETH',
        'amount': '1',
        'originalAmount': '1',
        'feeDeducted': '0',
        'feeDescription': 'none',
        'refundAddress': 'address',
      }),
      throwsA(isA<PegarouteCodecException>()),
    );
  });

  test('accepts empty warning providers but keeps warning fields typed', () {
    final warning = PegarouteWarning.fromJson({
      'provider': '',
      'code': 'NO_PROVIDER',
      'message': 'none',
      'userMessage': 'No provider available',
    });
    expect(warning.provider, isEmpty);
    expect(
      () => PegarouteWarning.fromJson({
        'provider': 1,
        'code': 'NO_PROVIDER',
        'message': 'none',
        'userMessage': 'No provider available',
      }),
      throwsA(isA<PegarouteCodecException>()),
    );
  });

  test('provider replacement and retry metadata cannot permit another POST', () async {
    final body = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    body['expiresAt'] = '2099-01-01T00:00:00Z';
    var posts = 0;
    final client = PegarouteApiClient(
      configuration: const PegarouteConfiguration(baseUrl: 'https://example.test'),
      get: (_, __) async => very_insecure_http_do_not_use.Response(json.encode(body), 200),
      post: (_, __, ___) async {
        posts++;
        return very_insecure_http_do_not_use.Response(json.encode({
          'error': {'code': 'PROVIDER_CHANGED', 'message': 'Do not display this',
            'userMessage': 'Do not display this', 'retryable': true, 'retryAfterSeconds': 0},
          'newQuote': {'untrusted': true}, 'originalProvider': 'instaswap', 'newProvider': 'thorchain',
        }), 409);
      },
    );
    final quote = await client.quote(PegarouteQuoteRequest(fromChain: 'ETH', fromToken: 'ETH',
        toChain: 'BTC', toToken: 'BTC', amount: '1', senderAddress: 'sender', destinationAddress: 'payout'));
    final route = quote.response.routes.single;
    final preflight = client.preflight(quote: quote, route: route,
      request: PegarouteSwapRequest(fromChain: 'ETH', fromToken: 'ETH', toChain: 'BTC', toToken: 'BTC',
        amount: '1', senderAddress: 'sender', destinationAddress: 'payout',
        quoteId: quote.response.quoteId, routeProvider: route.provider));
    await expectLater(client.swap(preflight), throwsA(isA<PegarouteSwapAttemptException>()
        .having((error) => error.userMessage, 'safe message', 'Pegaroute PROVIDER_CHANGED')));
    await expectLater(client.swap(preflight), throwsA(isA<PegarouteCodecException>()));
    expect(posts, 1);
  });

  test('rejects non-positive request amounts and empty token queries', () async {
    expect(
      () => PegarouteQuoteRequest(
        fromChain: 'ETH',
        fromToken: 'ETH',
        toChain: 'BTC',
        toToken: 'BTC',
        amount: '0',
      ),
      throwsA(isA<PegarouteCodecException>()),
    );
    expect(
      () => PegarouteQuoteRequest(
        fromChain: 'ETH',
        fromToken: 'ETH',
        toChain: 'BTC',
        toToken: 'BTC',
        amount: '1',
      ).toQuery(),
      returnsNormally,
    );
    await expectLater(
      PegarouteApiClient(
        configuration: const PegarouteConfiguration(baseUrl: 'https://example.test'),
      ).tokens(' '),
      throwsA(isA<PegarouteCodecException>()),
    );
  });

  test('rejects explicit null for optional non-nullable response fields', () {
    final quote = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    final route = (quote['routes'] as List).single as Map<String, dynamic>;
    route['subprovider'] = null;
    expect(() => PegarouteQuoteResponse.fromJson(quote), throwsA(isA<PegarouteCodecException>()));

    final status = json.decode(_fixture('status_refund.json')) as Map<String, dynamic>;
    (status['output'] as Map<String, dynamic>)['amount'] = null;
    expect(() => PegarouteStatusResponse.fromJson(status), throwsA(isA<PegarouteCodecException>()));

    final statusProvider = json.decode(_fixture('status_refund.json')) as Map<String, dynamic>;
    statusProvider['provider'] = null;
    expect(
      () => PegarouteStatusResponse.fromJson(statusProvider),
      throwsA(isA<PegarouteCodecException>()),
    );

    final openOcean = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    (openOcean['routes'] as List).single['openOceanRoute'] = {
      'dexId': 1,
      'dexCode': 'fixture',
      'dexes': null,
    };
    expect(
      () => PegarouteQuoteResponse.fromJson(openOcean),
      throwsA(isA<PegarouteCodecException>()),
    );

    final openOceanOmitted = json.decode(_fixture('quote.json')) as Map<String, dynamic>;
    (openOceanOmitted['routes'] as List).single['openOceanRoute'] = <String, dynamic>{};
    expect(PegarouteQuoteResponse.fromJson(openOceanOmitted), isA<PegarouteQuoteResponse>());

    final snapshot = json.decode(_fixture('status_refund.json')) as Map<String, dynamic>;
    (snapshot['input'] as Map<String, dynamic>)['instaswapSwapLite'] = null;
    expect(
      () => PegarouteStatusResponse.fromJson(snapshot),
      throwsA(isA<PegarouteCodecException>()),
    );

    expect(
      () => PegarouteInstaswapSnapshot.fromJson({
        'txid': 'fixture',
        'depositAddress': 'address',
        'depositAmountExact': null,
      }),
      throwsA(isA<PegarouteCodecException>()),
    );
  });

  test('amount constructors and decoders reject the same invalid values', () {
    for (final pair in [('1e2', '100'), ('-1', '1'), ('01', '1'), ('1', '-1'),
      ('1', '1.0'), ('', '1'), ('1', '')]) {
      expect(() => PegarouteTokenAmount(display: pair.$1, baseUnits: pair.$2),
          throwsA(isA<PegarouteCodecException>()));
      expect(() => PegarouteTokenAmount.fromJson({'display': pair.$1, 'baseUnits': pair.$2}),
          throwsA(isA<PegarouteCodecException>()));
    }
    final amount = PegarouteTokenAmount(display: '1.000000000000000001', baseUnits: '1000000000000000001');
    final json = amount.toJson()..['display'] = '2';
    expect(amount.display, '1.000000000000000001');
    expect(json['display'], '2');
  });

  test('direct execution construction checks the wire fields', () {
    final amount = PegarouteTokenAmount(display: '1', baseUnits: '1');
    for (final create in <PegarouteExecution Function()>[
      () => PegarouteExecution(family: 'evm', mode: 'native-transfer', chainId: 1,
          to: 'target', value: amount, data: '0x01'),
      () => PegarouteExecution(family: 'utxo', mode: 'payment-with-memo',
          to: 'target', amount: amount, chainId: 1),
      () => PegarouteExecution(family: 'solana', mode: 'serialized-tx',
          serializedTransaction: 'invalid!', encoding: 'base64'),
    ]) {
      expect(create, throwsA(isA<PegarouteCodecException>()));
    }
    final wire = _executionVariants().first;
    final execution = PegarouteExecution.fromJson(wire);
    wire['data'] = '0x00';
    execution.toJson()['data'] = '0x11';
    expect(execution.toJson()['data'], '0xabcdef');
  });

  test('Instaswap retains deposit terms and ignores unused display metadata', () {
    final value = <String, dynamic>{'txid': 'reference', 'depositAddress': 'address',
      'depositAmountExact': '1.000000000000000001', 'expiresAt': '2099-01-01T00:00:00Z',
      'feeBreakdown': null, 'estimatedOut': {}, 'estimatedOutUsd': [],
      'depositAmount': 'rounded', 'depositAmountUsd': false, 'etaSeconds': null,
      'depositTokenSymbol': 1, 'instructions': null};
    final snapshot = PegarouteInstaswapSnapshot.fromJson(value);
    expect(snapshot.txid, 'reference');
    expect(snapshot.depositAddress, 'address');
    expect(snapshot.depositAmountExact, '1.000000000000000001');
    expect(snapshot.expiresAt, '2099-01-01T00:00:00Z');
    value['expiresAt'] = null;
    expect(PegarouteInstaswapSnapshot.fromJson(value).expiresAt, isNull);
    value.remove('expiresAt');
    expect(PegarouteInstaswapSnapshot.fromJson(value).expiresAt, isNull);
    value['expiresAt'] = 1;
    expect(() => PegarouteInstaswapSnapshot.fromJson(value), throwsA(isA<PegarouteCodecException>()));
  });

  test('retained wire variants round trip without granting funding capability', () {
    for (final value in _executionVariants().where((v) => !_unsupportedFamilies.contains(v['family']))) {
      final decoded = PegarouteExecution.fromJson(value);
      final restored = PegarouteExecution.fromJson(decoded.toJson());
      expect(restored.toJson(), value);
    }
  });

  for (final family in _unsupportedFamilies) {
    test('rejects unsupported $family execution at the codec boundary', () {
      for (final value in _executionVariants().where((v) => v['family'] == family)) {
        expect(() => PegarouteExecution.fromJson(value), throwsA(isA<PegarouteCodecException>()));
        expect(() => PegarouteExecution(family: family, mode: value['mode'] as String),
            throwsA(isA<PegarouteCodecException>()));
      }
    });
  }
}
