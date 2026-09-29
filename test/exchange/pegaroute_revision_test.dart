import 'dart:convert';
import 'dart:io';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_store.dart';
import 'package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' show runInAction;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pegaroute_flow_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  setUpAll(() {
    registerFallbackValue(WalletType.ethereum);
    registerFallbackValue(Object());
    S.current = const S();
  });
  setUp(() async {
    db = await openDepositDb();
    evm = TestEvm(); monero = TestMonero();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async { await db.close(); sqlite.db = null; });

  test('backend-emitted precision survives exact quote/create and completed status', () async {
    final status = jsonDecode(File('test/exchange/fixtures/xmr-precision-poll.json').readAsStringSync()) as Map<String, dynamic>;
    const observed = '0.123456789012345678901';
    expect(status['output']['amount'], observed);
    final flow = DepositFixture(db);
    final route = {...flow.route, ...Map<String, dynamic>.from(status['route'] as Map<String, dynamic>),
      'expectedOutput': observed};
    // Keep the emitted observation verbatim; bind the fixture quote to this route.
    status['route'] = route;
    final provider = PegaRouteExchangeProvider(configuration: testPegarouteConfiguration,
        store: PegarouteTradeStore(db), request: (method, uri, headers, body) async {
      if (uri.path == '/chains' || uri.path == '/tokens') return flow.request(method, uri, headers, body);
      if (uri.path == '/quote') return {'quoteId': 'precision', 'expiresAt': '2099-01-01T00:00:00Z', 'routes': [route], 'warnings': []};
      if (method == 'POST') return {'transactionId': status['transactionId'], 'status': 'pending', 'route': route,
        'providerType': 'api-provider',
        'provider': status['provider'], 'execution': status['execution']};
      return status;
    });
    expect(await provider.fetchRateExact(from: CryptoCurrency.eth, to: CryptoCurrency.xmr, amount: '0.001'), greaterThan(0));
    final trade = await provider.createBoundTrade(request: TradeRequest(fromCurrency: CryptoCurrency.eth,
        toCurrency: CryptoCurrency.xmr, fromAmount: '0.001', toAddress: status['output']['address'] as String,
        refundAddress: status['input']['refundAddress'] as String), walletId: 'wallet', sender: status['input']['address'] as String,
        chainId: 1, isFixedRateMode: false, isSendAll: false, isCurrent: () => true);
    expect(trade.receiveAmount, observed);
    final updated = await provider.findTradeById(id: trade.id);
    expect(updated.receiveAmount, observed); expect(updated.stateRaw, 'success');
    expect(updated.outputTransaction, status['output']['txHash']);
    expect(await provider.fetchRateExact(from: CryptoCurrency.eth, to: CryptoCurrency.xmr,
        amount: '0.0000000000000000001'), 0);
  });

  for (final top in ['absent', 'matching', 'contradictory']) {
    test('supplied input provider reference fails closed with $top top-level provider', () async {
      final flow = DepositFixture(db); await flow.create();
      flow.status = 'completed';
      flow.rewriteStatus = (response) {
        (response['input'] as Map)['providerReferenceId'] = 'wrong-order';
        if (top != 'absent') response['provider'] = {'name': 'instaswap',
          'referenceId': top == 'matching' ? 'reference' : 'another-wrong-order'};
      };
      await expectLater(flow.provider.findTradeById(id: 'order'), throwsStateError);
      expect((await flow.store.read('order')).stateRaw, 'created');
    });
  }

  test('known Maya wire name is accepted as a route, not authority for unsupported execution', () async {
    final flow = DepositFixture(db);
    final route = {...flow.route, 'provider': 'maya'};
    final provider = PegaRouteExchangeProvider(configuration: testPegarouteConfiguration,
        request: (method, uri, headers, body) async {
      if (uri.path == '/chains' || uri.path == '/tokens') return flow.request(method, uri, headers, body);
      if (method == 'POST') return {'transactionId': 'unsupported', 'status': 'pending', 'providerType': 'api-provider',
        'route': route, 'provider': {'name': 'maya', 'referenceId': 'ref'},
        'execution': {'family': 'evm', 'mode': 'contract-call'}};
      return {'quoteId': 'q', 'expiresAt': '2099-01-01T00:00:00Z', 'routes': [route], 'warnings': []};
    });
    expect(await provider.fetchRateExact(from: CryptoCurrency.eth, to: CryptoCurrency.xmr, amount: flow.principal), greaterThan(0));
    await expectLater(provider.createBoundTrade(request: flow.intent, walletId: 'wallet',
        sender: flow.sender, chainId: 1, isFixedRateMode: false, isSendAll: false,
        isCurrent: () => true), throwsA(isA<PegarouteSwapAttemptException>()));
  });

  test('public branding remains Pegaroute without changing identifiers', () {
    expect(PegaRouteExchangeProvider().title, 'Pegaroute');
    expect(ExchangeProviderDescription.pegaRoute.title, 'Pegaroute');
  });

  test('native limits and safe structured errors retain only public code/numeric minimum', () async {
    final error = PegarouteApiError.fromJson(400, {'error': {'code': 'AMOUNT_TOO_LOW',
      'message': 'Sensitive upstream message', 'retryable': false, 'provider': 'instaswap',
      'userMessage': 'Minimum: 0.005 ETH; secret address 0x1111111111111111111111111111111111111111',
      'details': {'token': 'sensitive'}, 'request': 'do-not-echo'}});
    expect(error.toString(), contains('AMOUNT_TOO_LOW'));
    expect(error.userMessage, contains('0.005'));
    expect(error.toString(), isNot(contains('secret')));
    final flow = DepositFixture(db);
    final provider = PegaRouteExchangeProvider(configuration: testPegarouteConfiguration,
        request: (method, uri, headers, body) async {
      if (uri.path == '/quote') throw error;
      return flow.request(method, uri, headers, body);
    });
    final limits = await provider.fetchLimits(from: CryptoCurrency.eth, to: CryptoCurrency.xmr, isFixedRateMode: false);
    expect(limits!.min, 0);
    double? minimum;
    expect(await provider.fetchRateExact(from: CryptoCurrency.eth, to: CryptoCurrency.xmr,
        amount: '0.001', onLimits: (value) => minimum = value.min), 0);
    expect(minimum, 0.005);
    final routeProvider = PegaRouteExchangeProvider(configuration: testPegarouteConfiguration,
        request: (method, uri, headers, body) async {
      final result = await flow.request(method, uri, headers, body);
      if (uri.path == '/quote') ((result['routes'] as List).single as Map)['minAmount'] = '0.002';
      return result;
    });
    expect(await routeProvider.fetchRateExact(from: CryptoCurrency.eth, to: CryptoCurrency.xmr,
        amount: flow.principal, onLimits: (value) => minimum = value.min), greaterThan(0));
    expect(minimum, 0.002);
  });

  for (final change in ['wallet', 'amount', 'recipient']) {
    test('$change mutation during actual wallet preparation await prevents committing', () async {
      final flow = DepositFixture(db); final send = SendFixture(flow, await flow.create());
      send.duringBuild = () async {
        if (change == 'wallet') send.app.switchWallet(SendFixture(flow, send.trade).wallet);
        if (change == 'amount') runInAction(() => send.model.outputs.single.cryptoAmount = '2');
        if (change == 'recipient') runInAction(() => send.model.outputs.single.address = ethAddress);
      };
      expect(await send.prepare(), isNull);
      await send.commit(); expect(send.pending.commits, 0);
    });
  }

  for (final source in ['ETH', 'XMR']) {
    test('$source completion uses captured history, description, recipient preference and wallet', () async {
      final flow = DepositFixture(db, source: source); final send = SendFixture(flow, await flow.create());
      runInAction(() => send.model.outputs.single.note = 'original note');
      await send.prepare();
      send.pending.onCommit = () async {
        final replacement = SendFixture(flow, send.trade);
        when(() => replacement.wallet.name).thenReturn('replacement-wallet');
        when(() => replacement.addresses.primaryAddress).thenReturn('replacement-primary');
        send.app.switchWallet(replacement.wallet);
        when(() => send.settings.shouldSaveRecipientAddress).thenReturn(false);
        runInAction(() {
          send.model.outputs.single.address = 'replacement';
          send.model.outputs.single.note = 'replacement';
          send.model.pendingTransaction = TestPending(CryptoCurrency.xmr, '2');
        });
      };
      await send.commit();
      expect(send.model.state, isA<TransactionCommitted>());
      final hash = source == 'ETH' ? ethHash : xmrHash;
      expect(flow.notified, [hash]);
      final description = send.descriptionBox.descriptions.single;
      expect(description.id, '${hash}_${flow.sender}');
      expect(description.recipientAddress, flow.deposit);
      expect(description.transactionNote, 'original note');
      if (source == 'ETH') {
        expect(send.pending.id, isNot(ethHash));
        expect(send.history.transactions[ethHash]!.amount.toString(), flow.principal);
      } else {
        expect(description.transactionKey, 'offline-monero-tx-key');
      }
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(PreferencesKey.backgroundSyncLastTrigger('wallet')), isNotNull);
      expect(preferences.getString(PreferencesKey.backgroundSyncLastTrigger('replacement-wallet')), isNull);
    });
  }

  test('AUTOINCREMENT row identity rejects a stale deleted/recreated order without a JSON key', () async {
    final flow = DepositFixture(db); final old = await flow.create();
    await db.delete(Trade.tableName, where: 'tradeId = ?', whereArgs: [old.internalId]);
    final fresh = await flow.create();
    expect(fresh.internalId, greaterThan(old.internalId));
    expect(jsonDecode(fresh.routerData!).containsKey('key'), false);
    expect(await SendFixture(flow, old).prepare(), isNull);
  });

  test('recipient-save preference is respected by native completion', () async {
    final flow = DepositFixture(db); final send = SendFixture(flow, await flow.create());
    when(() => send.settings.shouldSaveRecipientAddress).thenReturn(false);
    await send.prepare(); await send.commit();
    expect(send.descriptionBox.descriptions.single.recipientAddress, isNull);
  });

  test('postcommit description failure is not payment failure or retry permission', () async {
    final flow = DepositFixture(db); final send = SendFixture(flow, await flow.create());
    await send.prepare(); send.descriptionBox.fail = true;
    await send.commit(); expect(send.model.state, isA<TransactionCommitted>());
    expect(await SendFixture(flow, await flow.store.read('order')).prepare(), isNull);
    expect(send.pending.commits, 1);
  });

  test('actual Swaps.xyz native send retains common history/description/preferences completion', () async {
    final flow = DepositFixture(db);
    final trade = Trade(id: 'ordinary-swap', amount: flow.principal, from: CryptoCurrency.eth,
        to: CryptoCurrency.xmr, provider: ExchangeProviderDescription.swapsXyz,
        inputAddress: flow.deposit, routerData: '0x');
    final send = SendFixture(flow, trade);
    expect(await send.model.createTransaction(provider: SwapsXyzExchangeProvider(), trade: trade), isNotNull);
    await send.commit();
    expect(send.model.state, isA<TransactionCommitted>());
    expect(send.history.transactions[ethHash], isNotNull);
    expect(send.descriptionBox.descriptions.single.recipientAddress, flow.deposit);
    expect(send.pending.commits, 1);
    expect((await SharedPreferences.getInstance()).getString(PreferencesKey.backgroundSyncLastTrigger('wallet')), isNotNull);
    expect(flow.notified, isEmpty);
  });
}
