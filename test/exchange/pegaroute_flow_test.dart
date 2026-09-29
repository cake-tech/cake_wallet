import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/core/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_record.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_store.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/send/fees_view_model.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_configuration.dart';
import 'fixtures/synthetic_evm.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart' show Observable, ObservableMap, runInAction;
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const ethDeposit = '0x2222222222222222222222222222222222222222';
final ethEnvelope = syntheticEvmEnvelope(to: ethDeposit, value: BigInt.parse('1000000000000000001'));
final ethAddress = ethEnvelope.sender;
final xmrAddress = '4${List.filled(94, 'A').join()}';
final ethHash = ethEnvelope.hash;
const testPegarouteConfiguration = PegarouteConfiguration(baseUrl: 'https://offline.invalid');
const fixtureFees = {'affiliate': '0', 'liquidity': '0', 'outbound': '0', 'total': '0'};
final xmrHash = List.filled(64, 'b').join();

class TestApp extends Mock implements AppStore {
  final walletChanges = Observable(0);
  @override
  WalletBase? get wallet {
    walletChanges.value;
    return super.noSuchMethod(Invocation.getter(#wallet)) as WalletBase?;
  }
  void switchWallet(WalletBase next) {
    when(() => wallet).thenReturn(next);
    runInAction(() => walletChanges.value++);
  }
}

class TestSettings extends Mock implements SettingsStore {}

class TestWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

class TestAddresses extends Mock implements WalletAddresses {}
class TestWalletInfo extends Mock implements WalletInfo {}

class TestResolver extends Mock implements AddressResolverService {}

class TestBalanceVM extends Mock implements BalanceViewModel {}

class TestContacts extends Mock implements ContactListViewModel {}

class TestFees extends Mock implements FeesViewModel {}

class TestTemplates extends Mock implements SendTemplateViewModel {}

class TestUnspent extends Mock implements UnspentCoinsListViewModel {}

class TestBox extends Mock implements Box<TransactionDescription> {
  final descriptions = <TransactionDescription>[];
  bool fail = false;
  @override
  Future<int> add(TransactionDescription value) async {
    if (fail) throw StateError('Synthetic description failure');
    descriptions.add(value);
    return descriptions.length - 1;
  }
}
class TestHistory extends TransactionHistoryBase<TransactionInfo> {
  @override
  void addOne(TransactionInfo tx) => transactions[tx.id] = tx;
  @override
  void addMany(Map<String, TransactionInfo> txs) => transactions.addAll(txs);
  @override
  Future<void> save() async {}
}
class TestTransactionInfo extends Mock implements TransactionInfo {}

class TestContext extends Mock implements BuildContext {}

class TestPriority extends TransactionPriority {
  const TestPriority() : super(title: 'Medium', raw: 1);
}

class TestBalance extends Balance {
  TestBalance(CryptoCurrency c) : super(Money.parse('100', c), Money.zero(c));
}

// Retain the real pure credential builders/history constructors; replace only wallet discovery.
class TestEvm extends CWEVM {
  @override
  List<Never> getAllChains() => [];
  @override
  List<Never> getERC20Currencies(WalletBase wallet) => [];
}

class TestMonero extends CWMonero {
  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) => (wallet as WalletBase).transactionHistory;
}

class TestPending with PendingTransaction {
  TestPending(this.currency, this.principal);
  final CryptoCurrency currency;
  final String principal;
  int commits = 0;
  bool unknown = false;
  bool ur = false;
  @override
  bool shouldCommitUR() => ur;
  Future<void> Function()? onCommit;
  @override
  String get id => currency == CryptoCurrency.eth ? 'different-pending-id' : xmrHash;
  @override
  String? get evmTxHashFromRawHex => currency == CryptoCurrency.eth ? ethHash : null;
  @override
  String get hex => currency == CryptoCurrency.eth ? ethEnvelope.hex : 'unsigned-offline-fixture';
  @override
  Money get amount => Money.parse(principal, currency);
  @override
  Money get fee => Money.parse('0.001', currency);
  @override
  String get amountFormatted => principal;
  @override
  Future<void> commit() async {
    commits++;
    await onCommit?.call();
    if (unknown) throw StateError('Synthetic lost broadcast response');
  }

  @override
  Future<Map<String, String>> commitUR() async => throw UnimplementedError();
}

Future<Database> openDepositDb({String path = inMemoryDatabasePath}) async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(path,
      options: OpenDatabaseOptions(singleInstance: false));
  final text = File('cw_core/lib/db/sqlite.dart').readAsStringSync();
  final start = text.indexOf('Future<void> _createTradeTable(');
  final end = text.indexOf('\n}', start);
  final sql =
      RegExp("await db.execute\\('''([\\s\\S]*?)'''\\)").allMatches(text.substring(start, end));
  for (final match in sql) {
    await db.execute(match.group(1)!);
  }
  expect((await db.rawQuery('PRAGMA table_info(Trade)')).length, 52);
  sqlite.db = db;
  return db;
}

class DepositFixture {
  DepositFixture(this.database, {this.source = 'ETH'}) {
    store = PegarouteTradeStore(database);
    provider = PegaRouteExchangeProvider(store: store, request: request, configuration: testPegarouteConfiguration);
  }
  final Database database;
  final String source;
  String get destination => source == 'ETH' ? 'XMR' : 'ETH';
  String get sender => source == 'ETH' ? ethAddress : xmrAddress;
  String get payout => source == 'ETH' ? xmrAddress : ethAddress;
  String get deposit => source == 'ETH' ? ethDeposit : xmrAddress;
  String get principal => source == 'ETH' ? '1.000000000000000001' : '1.000000000001';
  late final PegarouteTradeStore store;
  late final PegaRouteExchangeProvider provider;
  final notified = <String>[];
  final quoteAmounts = <String>[];
  int posts = 0;
  String status = 'pending';
  String? outputHash;
  Object? refund;
  bool corruptExecution = false;
  bool ambiguousCreate = false;
  Future<void> Function()? duringBoundQuote;
  String? statusRecipient;
  void Function(Map<String, dynamic>)? rewriteStatus;
  Completer<void>? statusRead;
  Completer<void>? releaseStatus;

  Map<String, dynamic> get route => {
        'provider': 'instaswap',
        'private': false,
        'expectedOutput': '0.9',
        'memo': null,
        'router': null,
        'providerType': 'api-provider', 'inboundAddress': null, 'gasRate': null,
        'minAmount': null, 'expiry': null, 'estimatedTimeSeconds': 120, 'fees': fixtureFees,
        'resolvedFee': {'feeBps': 0},
      };

  Future<Map<String, dynamic>> request(
      String method, Uri uri, Map<String, String> headers, String? body) async {
    if (uri.path == '/chains') return {'chains': [
      {'id': 'ETH', 'name': 'Ethereum', 'chainId': 1}, {'id': 'XMR', 'name': 'Monero', 'chainId': null}]};
    if (uri.path == '/tokens') {
      final chain = uri.queryParameters['chain']!;
      return {'chain': chain, 'tokens': [{'id': chain, 'symbol': chain}]};
    }
    if (uri.path == '/quote') {
      quoteAmounts.add(uri.queryParameters['amount']!);
      if (uri.queryParameters.containsKey('senderAddress')) await duringBoundQuote?.call();
      return {
        'quoteId': 'quote',
        'expiresAt': '2099-01-01T00:00:00Z',
        'routes': [route], 'warnings': []
      };
    }
    if (uri.path == '/swap') {
      posts++;
      final sent = jsonDecode(body!) as Map<String, dynamic>;
      expect(sent['amount'], principal);
      expect(sent['senderAddress'], sender);
      expect(sent['routeProvider'], 'instaswap');
      if (ambiguousCreate) throw StateError('Synthetic POST timeout');
      final money = {
        'display': principal,
        'baseUnits': PegarouteTradeRecord.units(principal, source).toString()
      };
      var mode = source == 'ETH' ? 'native-transfer' : 'deposit-transfer';
      if (corruptExecution) mode = 'contract-call';
      return {
        'transactionId': 'order',
        'status': 'pending',
        'providerType': 'api-provider',
        'route': route,
        'provider': {'name': 'instaswap', 'referenceId': 'reference'},
        'execution': {
          'family': source == 'ETH' ? 'evm' : 'other',
          'mode': mode,
          if (source == 'ETH') ...{'chainId': 1, 'data': null, 'gasLimit': null,
            'approval': null, 'transferAmount': null},
          if (source != 'ETH') 'chain': source,
          'memo': null,
          'to': deposit,
          if (source == 'ETH') 'value': money,
          if (source == 'XMR') 'amount': money
        }
      };
    }
    if (uri.path.endsWith('/txhash')) {
      final hash = (jsonDecode(body!) as Map<String, dynamic>)['txHash'] as String;
      notified.add(hash);
      return {'transactionId': 'order', 'txHash': hash, 'status': 'submitted'};
    }
    final result = <String, dynamic>{
      'transactionId': 'order',
      'internalStatus': status,
      'status': switch (status) {
        'pending' => 'pending',
        'completed' => 'success',
        'failed' || 'refunded' => 'fail',
        _ => 'executing'
      },
      'route': route,
      'fees': fixtureFees, 'timestamps': {'created': '2026-01-01T00:00:00Z'},
      'input': {
        'chain': source,
        'token': source,
        'amount': principal,
        'address': sender,
        'refundAddress': sender,
        'providerReferenceId': 'reference'
      },
      'output': {
        'chain': destination,
        'token': destination,
        'address': statusRecipient ?? payout,
        if (outputHash != null) 'txHash': outputHash,
        'amount': '0.8'
      },
      'refund': refund, 'error': null, 'streamingProgress': null
    };
    rewriteStatus?.call(result);
    if (statusRead?.isCompleted == false) statusRead!.complete();
    await releaseStatus?.future;
    return result;
  }

  TradeRequest get intent => TradeRequest(
      fromCurrency: PegarouteTradeRecord.currency(source),
      toCurrency: PegarouteTradeRecord.currency(destination),
      fromAmount: principal,
      toAddress: payout,
      refundAddress: sender);

  Future<Trade> create() async {
    await provider.fetchRateExact(
        from: intent.fromCurrency, to: intent.toCurrency, amount: principal);
    return provider.createBoundTrade(request: intent, walletId: 'wallet', sender: sender,
        chainId: source == 'ETH' ? 1 : null, isCurrent: () => true,
        isFixedRateMode: false, isSendAll: false);
  }
}

class SendFixture {
  SendFixture(this.flow, this.trade) {
    final currency = PegarouteTradeRecord.currency(flow.source);
    pending = TestPending(currency, flow.principal);
    when(() => app.wallet).thenReturn(wallet);
    when(() => app.settingsStore).thenReturn(settings);
    when(() => app.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin));
    when(() => settings.fiatCurrency).thenReturn(FiatCurrency.usd);
    when(() => settings.useBlinkProtection).thenReturn(false);
    when(() => settings.shouldSaveRecipientAddress).thenReturn(true);
    when(() => settings.getPriority(any(), chainId: any(named: 'chainId')))
        .thenReturn(flow.source == 'ETH' ? TestEvm().getDefaultTransactionPriority() : MoneroTransactionPriority.medium);
    when(() => wallet.currency).thenReturn(currency);
    when(() => wallet.type)
        .thenReturn(flow.source == 'ETH' ? WalletType.ethereum : WalletType.monero);
    when(() => wallet.id).thenReturn('wallet');
    when(() => wallet.name).thenReturn('wallet');
    when(() => wallet.chainId).thenReturn(flow.source == 'ETH' ? 1 : null);
    when(() => wallet.isHardwareWallet).thenReturn(false);
    when(() => wallet.isSoftwareWallet).thenReturn(true);
    final info = TestWalletInfo();
    when(() => info.network).thenReturn('mainnet');
    when(() => wallet.walletInfo).thenReturn(info);
    when(() => wallet.updateTransactionsHistory()).thenAnswer((_) async {});
    when(() => wallet.updateBalance()).thenAnswer((_) async {});
    when(() => wallet.fetchTransactions()).thenAnswer((_) async => history.transactions);
    when(() => wallet.transactionHistory).thenReturn(history);
    final tx = TestTransactionInfo();
    when(() => tx.id).thenReturn(xmrHash);
    when(() => tx.additionalInfo).thenReturn({'key': 'offline-monero-tx-key'});
    history.transactions[xmrHash] = tx;
    when(() => wallet.syncStatus).thenReturn(StartingScanSyncStatus(0));
    when(() => wallet.walletAddresses).thenReturn(addresses);
    when(() => addresses.address).thenReturn(flow.sender);
    when(() => addresses.addressForExchange).thenReturn(flow.sender);
    when(() => addresses.primaryAddress).thenReturn(flow.sender);
    when(() => addresses.hiddenAddresses).thenReturn(<String>{});
    when(() => addresses.saveAddressesInBox()).thenAnswer((_) async {});
    when(() => wallet.balance).thenReturn(ObservableMap.of({currency: TestBalance(currency)}));
    when(() => wallet.createTransaction(any())).thenAnswer((invocation) async {
      builds++;
      final dynamic credentials = invocation.positionalArguments.single;
      final nativeOutputs = (credentials.outputs as List<dynamic>).cast<OutputInfo>();
      if (flow.source == 'ETH') expect(credentials.currency, currency);
      expect(nativeOutputs.single.address, flow.deposit);
      expect(nativeOutputs.single.cryptoAmount.toString(), flow.principal);
      expect(nativeOutputs.single.sendAll, false);
      expect(nativeOutputs.single.isParsedAddress, false);
      await duringBuild?.call();
      return pending;
    });
    when(() => unspent.initialSetup()).thenAnswer((_) async {});
    when(() => unspent.getSendingBalance(UnspentCoinType.any))
        .thenAnswer((_) async => 100000000000000);
    model = SendViewModel(app, TestTemplates(), FiatConversionStore(), TestResolver(),
        TestBalanceVM(), TestContacts(), descriptionBox, null, unspent, TestFees());
    runInAction(() {
      model.outputs.single.address = flow.deposit;
      model.outputs.single.cryptoAmount = flow.principal;
    });
  }
  final DepositFixture flow;
  final Trade trade;
  final app = TestApp();
  final settings = TestSettings();
  final wallet = TestWallet();
  final addresses = TestAddresses();
  final unspent = TestUnspent();
  final history = TestHistory();
  final descriptionBox = TestBox();
  late final SendViewModel model;
  late final TestPending pending;
  int builds = 0;
  Future<void> Function()? duringBuild;
  Future<PendingTransaction?> prepare() =>
      model.createTransaction(provider: flow.provider, trade: trade);
  Future<void> commit() => model.commitTransaction(TestContext());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database database;
  setUpAll(() {
    registerFallbackValue(WalletType.ethereum);
    registerFallbackValue(Object());
    S.current = const S();
  });
  setUp(() async {
    database = await openDepositDb();
    SharedPreferences.setMockInitialValues({});
    evm = TestEvm();
    monero = TestMonero();
  });
  tearDown(() async {
    await database.close();
    sqlite.db = null;
  });

  for (final source in ['ETH', 'XMR']) {
    test('$source real provider/create + SendViewModel prepare/commit + notification/status',
        () async {
      final flow = DepositFixture(database, source: source);
      final trade = await flow.create();
      final send = SendFixture(flow, trade);
      expect(await send.prepare(), isNotNull);
      send.pending.onCommit = () async {
        expect(PegarouteTradeRecord.read(await flow.store.read('order')).attempt, isNotNull);
      };
      await send.commit();
      expect(send.model.state, isA<TransactionCommitted>());
      expect(send.pending.commits, 1);
      expect(flow.notified, [send.pending.evmTxHashFromRawHex ?? send.pending.id]);
      expect(flow.quoteAmounts, everyElement(flow.principal));
      final submitted = await flow.store.read('order');
      expect(submitted.txId, send.pending.evmTxHashFromRawHex ?? send.pending.id);
      expect(submitted.stateRaw, 'created'); // local send is not provider payout proof
      flow.status = 'submitted';
      expect((await flow.provider.findTradeById(id: trade.id)).stateRaw, 'confirming');
      flow.status = 'completed';
      final completed = await flow.provider.findTradeById(id: trade.id);
      expect(completed.stateRaw, 'success');
      expect(PegarouteTradeRecord.read(completed).attempt, isNotNull);
      await send.commit();
      expect(send.pending.commits, 1);
    });
  }

  test('stale provider refresh merges with a concurrent funding claim', () async {
    final flow = DepositFixture(database);
    final send = SendFixture(flow, await flow.create());
    await send.prepare();
    flow.statusRead = Completer<void>();
    flow.releaseStatus = Completer<void>();
    final refresh = flow.provider.findTradeById(id: 'order');
    await flow.statusRead!.future;
    await send.commit();
    flow.releaseStatus!.complete();
    final result = await refresh;
    expect(result.txId, ethHash);
    expect(PegarouteTradeRecord.read(result).attempt, isNotNull);
    expect(await SendFixture(flow, result).prepare(), isNull);
  });

  for (final change in ['wallet', 'amount', 'recipient', 'output']) {
    test('changed $change rejects commit of an already prepared deposit', () async {
      final flow = DepositFixture(database);
      final trade = await flow.create();
      final send = SendFixture(flow, trade);
      await send.prepare();
      if (change == 'wallet') when(() => send.wallet.id).thenReturn('different');
      if (change == 'amount') trade.amount = '2';
      if (change == 'recipient') trade.payoutAddress = ethAddress;
      if (change == 'output') runInAction(() => send.model.outputs.single.address = ethAddress);
      await send.commit();
      expect(send.pending.commits, 0);
      expect(send.model.state, isA<FailureState>());
    });
  }

  test('payout evidence and corrupt records reject preparation', () async {
    final flow = DepositFixture(database);
    final trade = await flow.create();
    flow.outputHash = xmrHash;
    await flow.provider.findTradeById(id: 'order');
    expect(await SendFixture(flow, trade).prepare(), isNull);
    await database.update('Trade', {'routerData': '{}'});
    expect(await SendFixture(flow, trade).prepare(), isNull);
    await database.update('Trade', {'routerData': null});
    await expectLater(flow.provider.findTradeById(id: 'order'), throwsA(anything));
  });

  test('status recipient mismatch never changes persisted intent or progress', () async {
    final flow = DepositFixture(database);
    final trade = await flow.create();
    flow.statusRecipient = 'wrong';
    flow.status = 'completed';
    await expectLater(flow.provider.findTradeById(id: 'order'), throwsStateError);
    expect((await flow.store.read('order')).routerData, trade.routerData);
    expect((await flow.store.read('order')).stateRaw, 'created');
  });

  test('unknown broadcast survives database close/reopen and forbids another payment', () async {
    final directory = await Directory.systemTemp.createTemp('pegaroute-r3-');
    final path = '${directory.path}/trade.db';
    var fileDb = await openDepositDb(path: path);
    try {
      final flow = DepositFixture(fileDb);
      final send = SendFixture(flow, await flow.create());
      await send.prepare();
      send.pending.unknown = true;
      await send.commit();
      expect(send.pending.commits, 1);
      expect(flow.notified, isEmpty);
      await fileDb.close();
      fileDb = await openDepositDb(path: path);
      final restored = DepositFixture(fileDb);
      final trade = await restored.store.read('order');
      expect(trade.txId, isNull);
      expect(PegarouteTradeRecord.read(trade).attempt, isNotNull);
      final retry = SendFixture(restored, trade);
      expect(await retry.prepare(), isNull);
      expect(retry.builds, 0);
    } finally {
      await fileDb.close();
      await directory.delete(recursive: true);
      sqlite.db = database;
    }
  });

  test('refund polls preserve known hashes and completion while keeping configured intent', () async {
    final flow = DepositFixture(database);
    await flow.create();
    flow.status = 'refunded';
    final observation = <String, dynamic>{'status': 'completed', 'refundAddress': 'observed-return',
      'chain': flow.source, 'amount': '0.9', 'originalAmount': flow.principal,
      'feeDeducted': '0.1', 'feeDescription': 'Fixture fee',
      'txHash': '0x${'d' * 64}', 'completedAt': '2026-01-01T00:00:00Z'};
    flow.refund = observation;
    await flow.provider.findTradeById(id: 'order');
    flow.refund = {...observation}..remove('txHash')..remove('completedAt');
    await flow.provider.findTradeById(id: 'order');
    flow.refund = {...observation, 'status': 'pending'}..remove('txHash')..remove('completedAt');
    final saved = await flow.provider.findTradeById(id: 'order');
    final refund = PegarouteTradeRecord.read(saved).refund!;
    expect(refund['status'], 'completed');
    expect(refund['txHash'], observation['txHash']);
    expect(refund['completedAt'], observation['completedAt']);
    expect(refund['refundAddress'], 'observed-return');
    expect(saved.refundAddress, flow.sender);
    expect(saved.txId, isNull);
    expect(saved.outputTransaction, isNull);
    flow.refund = {...observation, 'txHash': '0x${'e' * 64}'};
    await expectLater(flow.provider.findTradeById(id: 'order'), throwsStateError);
    expect((await flow.store.read('order')).routerData, saved.routerData);
  });

  for (final invalidRefund in [{'chain': 'XMR'}, {'txHash': '0x123'}, {'amount': '-1'}]) {
    test('invalid refund observation rolls back all progress: $invalidRefund', () async {
      final flow = DepositFixture(database);
      final original = await flow.create();
      flow.refund = {'status': 'pending', 'refundAddress': 'observed-return',
        'chain': flow.source, 'amount': '0.9', 'originalAmount': flow.principal,
        'feeDeducted': '0.1', 'feeDescription': 'Fixture fee', ...invalidRefund};
      await expectLater(flow.provider.findTradeById(id: 'order'), throwsA(anything));
      final saved = await flow.store.read('order');
      expect(saved.routerData, original.routerData);
      expect(saved.isRefund, isNot(true));
    });
  }

  for (final progress in ['submitted', 'executing', 'confirming', 'failed', 'refunded', 'refund']) {
    test('provider $progress evidence blocks a fresh native payment', () async {
      final flow = DepositFixture(database);
      final trade = await flow.create();
      if (progress == 'refund') {
        flow.refund = {'status': 'pending', 'refundAddress': 'observed-recipient',
          'chain': flow.source, 'amount': '0.9', 'originalAmount': flow.principal,
          'feeDeducted': '0.1', 'feeDescription': 'Fixture fee'};
      } else {
        flow.status = progress;
      }
      final updated = await flow.provider.findTradeById(id: 'order');
      expect(updated.refundAddress, flow.sender);
      final send = SendFixture(flow, trade);
      expect(await send.prepare(), isNull);
      expect(send.builds, 0);
    });
  }

  test('two actual send models cannot commit the same order twice', () async {
    final flow = DepositFixture(database);
    final trade = await flow.create();
    final first = SendFixture(flow, trade);
    final second = SendFixture(flow, trade);
    await first.prepare();
    await second.prepare();
    await Future.wait([first.commit(), second.commit()]);
    expect(first.pending.commits + second.pending.commits, 1);
    expect(flow.notified.length, 1);
  });

  test('commit uses the captured pending hash even when the public pending field changes',
      () async {
    final flow = DepositFixture(database);
    final send = SendFixture(flow, await flow.create());
    await send.prepare();
    send.pending.onCommit = () async {
      runInAction(() => send.model.pendingTransaction = TestPending(CryptoCurrency.xmr, '1'));
    };
    await send.commit();
    expect(flow.notified, [ethHash]);
    expect((await flow.store.read('order')).txId, ethHash);
  });

  test('wallet preparation awaits cannot hide changed recipient or output', () async {
    final flow = DepositFixture(database);
    final trade = await flow.create();
    final send = SendFixture(flow, trade);
    send.duringBuild = () async {
      trade.payoutAddress = 'changed';
    };
    expect(await send.prepare(), isNull);
    expect(send.builds, 1);
    expect(send.pending.commits, 0);
  });

  test('actual SendViewModel preserves a one-wei structured affordability shortfall', () async {
    final flow = DepositFixture(database);
    final send = SendFixture(flow, await flow.create());
    send.duringBuild = () async { throw TransactionWrongBalanceException(CryptoCurrency.eth,
      requiredBalance: Money.parse('1.000000000000000001', CryptoCurrency.eth),
      availableBalance: Money.parse('1', CryptoCurrency.eth),
      fee: Money.fromInt(1, CryptoCurrency.eth)); };
    expect(await send.prepare(), isNull);
    expect((send.model.state as FailureState).error, contains('0.000000000000000001'));
    expect(send.pending.commits, 0);
    expect(PegarouteTradeRecord.read(await flow.store.read('order')).attempt, isNull);
  });

  for (final unsupported in ['hardware', 'network', 'UR', 'send-all', 'memo']) {
    test('$unsupported never falls through to generic deposit sending', () async {
      final flow = DepositFixture(database);
      final send = SendFixture(flow, await flow.create());
      if (unsupported == 'hardware') when(() => send.wallet.isHardwareWallet).thenReturn(true);
      if (unsupported == 'network') when(() => send.wallet.walletInfo.network).thenReturn('testnet');
      if (unsupported == 'UR') send.pending.ur = true;
      if (unsupported == 'send-all') runInAction(() => send.model.outputs.single.sendAll = true);
      if (unsupported == 'memo') runInAction(() => send.model.outputs.single.memo = 'memo');
      expect(await send.prepare(), isNull);
      await send.commit();
      expect(send.pending.commits, 0);
      expect(flow.notified, isEmpty);
    });
  }

  test('claim persistence failure prevents broadcast', () async {
    final flow = DepositFixture(database);
    final send = SendFixture(flow, await flow.create());
    await send.prepare();
    await database.execute('PRAGMA query_only = ON');
    await send.commit();
    await database.execute('PRAGMA query_only = OFF');
    expect(send.pending.commits, 0);
    expect(flow.notified, isEmpty);
    expect(send.model.state, isA<FailureState>());
  });

  test('ordinary other-provider Trade save/replace/delete remains unchanged', () async {
    final trade = Trade(
        id: 'ordinary',
        amount: '1',
        provider: ExchangeProviderDescription.jupiter,
        routerData: 'opaque-jupiter-payload');
    await trade.save();
    trade.amount = '2';
    await trade.save();
    expect((await Trade.getByTradeId(trade.id))!.routerData, 'opaque-jupiter-payload');
    await Trade(id: trade.id, amount: '3').save();
    final replacement = (await Trade.getByTradeId(trade.id))!;
    expect(replacement.amount, '3');
    expect(await Trade.deleteTrade(replacement), 1);
  });

  test('unsupported API execution never becomes an ordinary wallet transfer', () async {
    final flow = DepositFixture(database)..corruptExecution = true;
    await expectLater(flow.create(), throwsA(isA<PegarouteSwapAttemptException>()));
    expect(await Trade.getByTradeId('order'), isNull);
    expect(flow.posts, 1);
  });
}
