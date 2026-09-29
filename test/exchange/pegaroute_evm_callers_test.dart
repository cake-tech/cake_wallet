import 'dart:convert';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_api.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_currency_mapper.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_record.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_preparation_retry.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/evm_call_data_transaction_credentials.dart';
// Offline test inspects real core history, not an application-side coin import.
// ignore: cw_custom_lints/no_restricted_imports_in_lib
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' show ObservableMap, runInAction;
import 'package:cake_wallet/core/execution_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'fixtures/synthetic_evm.dart';
import 'pegaroute_flow_test.dart';

class ReceiptEvm extends TestEvm {
  BigInt allowance = BigInt.zero;
  bool? receipt;
  int receiptReads = 0;
  @override
  Future<BigInt?> getAllowance(WalletBase wallet, String tokenAddress, String spender) async => allowance;
  @override
  Future<bool?> getTransactionReceipt(WalletBase wallet, String hash) async {
    receiptReads++;
    return receipt;
  }
}

class EnvelopePending extends TestPending {
  EnvelopePending(this.envelope) : super(CryptoCurrency.eth, '0');
  final ({String hex, String sender, String hash}) envelope;
  @override
  String get hex => envelope.hex;
  @override
  String get id => envelope.hash;
  @override
  String? get evmTxHashFromRawHex => envelope.hash;
  @override
  Money get fee => Money.parse('0.0026', CryptoCurrency.eth);
}

class TokenFlow extends DepositFixture {
  TokenFlow(super.database, {this.call = false, this.approval = false,
      this.approvalEnvelope = false, this.reset = false, this.customToken = false,
      this.zeroApproval});
  final bool call, approval, approvalEnvelope, reset, customToken;
  final bool? zeroApproval;
  @override
  Future<Trade> create() async {
    try { return await super.create(); }
    on PegarouteSwapAttemptException catch (error, stack) {
      // Synthetic fixtures only: expose the retained cause to diagnose tests.
      Error.throwWithStackTrace(error.cause, stack);
    }
  }
  late final token = Erc20Token(name: reset ? 'Tether' : 'USD Coin', symbol: reset ? 'USDT' : 'USDC',
      contractAddress: customToken ? '0x3333333333333333333333333333333333333333'
          : reset ? '0xdac17f958d2ee523a2206206994597c13d831ec7'
          : '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', decimal: 6, chainId: 1);
  String get tokenId => const PegarouteCurrencyMapper().map(token).token;
  @override
  String get principal => '1.25';
  String get transferData => '0xa9059cbb${ethDeposit.substring(2).padLeft(64, '0')}${BigInt.from(1250000).toRadixString(16).padLeft(64, '0')}';
  String get approvalData => '0x095ea7b3${ethDeposit.substring(2).padLeft(64, '0')}${((zeroApproval ?? reset) ? BigInt.zero : BigInt.from(1250000)).toRadixString(16).padLeft(64, '0')}';
  late final envelope = syntheticEvmEnvelope(to: approvalEnvelope || !call ? token.contractAddress : ethDeposit,
      value: BigInt.zero, data: approvalEnvelope ? approvalData : call ? '0x1234' : transferData, gas: 65000);
  @override
  String get sender => envelope.sender;
  @override
  Map<String, dynamic> get route => {...super.route, 'provider': call ? 'openocean' : 'instaswap'};
  @override
  TradeRequest get intent => TradeRequest(fromCurrency: token, toCurrency: CryptoCurrency.xmr,
      fromAmount: principal, toAddress: payout, refundAddress: sender);
  @override
  Future<Map<String, dynamic>> request(String method, Uri uri, Map<String, String> headers, String? body) async {
    if (uri.path == '/tokens' && uri.queryParameters['chain'] == 'ETH') {
      return {'chain': 'ETH', 'tokens': [{'id': 'ETH', 'symbol': 'ETH'}, {'id': tokenId, 'symbol': token.title}]};
    }
    if (uri.path == '/swap') {
      posts++;
      final sent = jsonDecode(body!) as Map;
      expect(sent['fromToken'], tokenId);
      expect(sent['amount'], principal);
      return {'transactionId': 'order', 'status': 'pending', 'providerType': 'api-provider',
        'route': route, 'provider': {'name': route['provider'], 'referenceId': 'reference'},
        'execution': {'family': 'evm', 'mode': call ? 'contract-call' : 'erc20-transfer', 'chainId': 1,
          'to': ethDeposit, 'memo': null, 'gasLimit': null, 'data': call ? '0x1234' : null,
          'value': null, 'transferAmount': call ? null : {'display': principal, 'baseUnits': '1250000'},
          'approval': approval ? {'tokenAddress': token.contractAddress, 'spender': ethDeposit,
            'amount': {'display': principal, 'baseUnits': '1250000'}} : null}};
    }
    final result = await super.request(method, uri, headers, body);
    if (uri.path == '/swap/order' && method == 'GET') (result['input'] as Map)['token'] = tokenId;
    return result;
  }
}

class NativeChainFlow extends DepositFixture {
  NativeChainFlow(Database database, String chain, this.network) : super(database, source: chain);
  final int network;
  @override
  String get principal => '1.25';
  @override
  String get deposit => ethDeposit;
  late final envelope = syntheticEvmEnvelope(to: deposit,
      value: PegarouteTradeRecord.units(principal, source), chainId: network);
  @override
  String get sender => envelope.sender;
  @override
  Future<Trade> create() async {
    await provider.fetchRateExact(from: intent.fromCurrency, to: intent.toCurrency, amount: principal);
    return provider.createBoundTrade(request: intent, walletId: 'wallet', sender: sender,
        chainId: network, isFixedRateMode: false, isSendAll: false, isCurrent: () => true);
  }
  @override
  Future<Map<String, dynamic>> request(String method, Uri uri, Map<String, String> headers, String? body) async {
    final native = const PegarouteCurrencyMapper().map(intent.fromCurrency).token;
    if (uri.path == '/chains') return {'chains': [
      {'id': source, 'name': source, 'chainId': network}, {'id': 'ETH', 'name': 'Ethereum', 'chainId': 1}]};
    if (uri.path == '/tokens' && uri.queryParameters['chain'] == source) {
      return {'chain': source, 'tokens': [{'id': native, 'symbol': native}]};
    }
    if (uri.path == '/swap') return {'transactionId': 'order', 'status': 'pending', 'providerType': 'api-provider',
      'route': route, 'provider': {'name': 'instaswap', 'referenceId': 'reference'},
      'execution': {'family': 'evm', 'mode': 'native-transfer', 'chainId': network,
        'to': deposit, 'memo': null, 'gasLimit': null, 'data': null, 'approval': null, 'transferAmount': null,
        'value': {'display': principal, 'baseUnits': PegarouteTradeRecord.units(principal, source).toString()}}};
    return super.request(method, uri, headers, body);
  }
}
class NativeChainPending extends TestPending {
  NativeChainPending(this.flow) : super(flow.intent.fromCurrency, flow.principal);
  final NativeChainFlow flow;
  @override
  String get hex => flow.envelope.hex;
}

(SendFixture, EnvelopePending) tokenSend(TokenFlow flow, Trade trade) {
  final send = SendFixture(flow, trade);
  final pending = EnvelopePending(flow.envelope);
  when(() => send.wallet.balance).thenReturn(ObservableMap.of({
    CryptoCurrency.eth: TestBalance(CryptoCurrency.eth), flow.token: TestBalance(flow.token)}));
  when(() => send.wallet.createTransaction(any())).thenAnswer((invocation) async {
    send.builds++;
    final credentials = invocation.positionalArguments.single as EvmCallDataTransactionCredentials;
    expect(credentials.to, flow.approvalEnvelope || !flow.call ? flow.token.contractAddress : ethDeposit);
    expect(credentials.data, flow.approvalEnvelope ? flow.approvalData : flow.call ? '0x1234' : flow.transferData);
    expect(credentials.value.amount, BigInt.zero);
    if (!flow.approvalEnvelope) {
      expect(credentials.sourceTokenAddress, flow.token.contractAddress);
      expect(credentials.sourceTokenAmount, BigInt.from(1250000));
    }
    return pending;
  });
  runInAction(() {
    send.model.selectedCryptoCurrency = flow.token;
    send.model.outputs.single.setCryptoAmount(flow.principal);
  });
  return (send, pending);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late ReceiptEvm facade;
  setUpAll(() {
    registerFallbackValue(WalletType.ethereum);
    registerFallbackValue(Object());
    S.current = const S();
  });
  setUp(() async {
    db = await openDepositDb();
    facade = ReceiptEvm(); evm = facade;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async { await db.close(); sqlite.db = null; });

  const networks = {'BSC': (56, WalletType.bsc), 'BASE': (8453, WalletType.base),
    'ARBITRUM': (42161, WalletType.arbitrum), 'POLYGON': (137, WalletType.polygon)};
  for (final entry in networks.entries) {
    test('${entry.key} native signed-envelope binding through actual SendViewModel', () async {
      final flow = NativeChainFlow(db, entry.key, entry.value.$1);
      final trade = await flow.create();
      final send = SendFixture(flow, trade);
      final pending = NativeChainPending(flow);
      when(() => send.wallet.type).thenReturn(entry.value.$2);
      when(() => send.wallet.chainId).thenReturn(entry.value.$1);
      when(() => send.settings.getPriority(any(), chainId: any(named: 'chainId')))
          .thenReturn(facade.getDefaultTransactionPriority());
      when(() => send.wallet.createTransaction(any())).thenAnswer((call) async {
        final dynamic credentials = call.positionalArguments.single;
        expect(credentials.currency, flow.intent.fromCurrency);
        expect(credentials.outputs.single.cryptoAmount.toString(), flow.principal);
        return pending;
      });
      expect(await send.prepare(), isNotNull);
      await send.commit();
      expect(pending.commits, 1);
      expect((await flow.store.read('order')).txId, flow.envelope.hash);
      expect(flow.notified, [flow.envelope.hash]);
    });
  }

  for (final call in [false, true]) {
    test('${call ? 'opaque call' : 'ERC20 transfer'} actual create, restore, SendViewModel and commit', () async {
      final flow = TokenFlow(db, call: call);
      final trade = await flow.create();
      final restored = await flow.store.read(trade.id);
      expect((restored.from as Erc20Token).contractAddress, flow.token.contractAddress);
      final (send, pending) = tokenSend(flow, restored);
      expect(await send.prepare(), isNotNull);
      pending.onCommit = () async {
        expect(PegarouteTradeRecord.read(await flow.store.read('order')).attempt, isNotNull);
      };
      await send.commit();
      expect(pending.commits, 1);
      expect((await flow.store.read('order')).txId, flow.envelope.hash);
      expect(flow.notified, [flow.envelope.hash]);
      final history = send.history.transactions[flow.envelope.hash] as EVMChainTransactionInfo;
      expect(history.contractAddress, flow.token.contractAddress);
      expect(history.amount.currency, isA<Erc20Token>());
      expect(send.model.state, isA<TransactionCommitted>());
    });
  }

  for (final reset in [false, true]) {
    test('${reset ? 'USDT reset' : 'approval'} has a separate durable claim and never funds on unknown receipt', () async {
      final flow = TokenFlow(db, call: true, approval: true, approvalEnvelope: true, reset: reset);
      facade.allowance = reset ? BigInt.one : BigInt.zero;
      final trade = await flow.create();
      final (send, pending) = tokenSend(flow, trade);
      expect(await send.prepare(), isNotNull);
      pending.onCommit = () async {
        final saved = await flow.store.read('order');
        expect(saved.txId, isNull);
        expect(PegarouteTradeRecord.read(saved).approvals.keys, [reset ? 'reset' : 'approve']);
      };
      await send.commit();
      expect(pending.commits, 1);
      expect((await flow.store.read('order')).txId, isNull);
      expect(flow.notified, isEmpty);
      expect(send.model.state, isA<FailureState>());
      expect(await pegaroutePreparationRetryAction(trade: trade, wallet: send.wallet),
          PegaroutePreparationRetryAction.checkApproval);
      expect(await send.prepare(), isNull);
      expect(pending.commits, 1);
      facade.receipt = false;
      expect(await send.prepare(), isNull);
      expect(await pegaroutePreparationRetryAction(trade: trade, wallet: send.wallet), isNull);
    });
  }

  test('two prepared approval callers compete for one durable slot', () async {
    final flow = TokenFlow(db, call: true, approval: true, approvalEnvelope: true);
    final trade = await flow.create();
    final (first, firstPending) = tokenSend(flow, trade);
    final (second, secondPending) = tokenSend(flow, trade);
    expect(await first.prepare(), isNotNull);
    expect(await second.prepare(), isNotNull);
    await Future.wait([first.commit(), second.commit()]);
    expect(firstPending.commits + secondPending.commits, 1);
    final saved = await flow.store.read('order');
    expect(PegarouteTradeRecord.read(saved).approvals.keys, ['approve']);
    expect(saved.txId, isNull);
    expect(flow.notified, isEmpty);
  });

  test('ambiguous approval broadcast remains consumed after reload', () async {
    final flow = TokenFlow(db, call: true, approval: true, approvalEnvelope: true);
    final trade = await flow.create();
    final (send, pending) = tokenSend(flow, trade);
    expect(await send.prepare(), isNotNull);
    pending.unknown = true;
    await send.commit();
    final saved = await flow.store.read('order');
    expect(saved.txId, isNull);
    expect(PegarouteTradeRecord.read(saved).approvals['approve']['state'], 'claimed');
    expect(await send.prepare(), isNull);
    await send.commit();
    expect(pending.commits, 1);
    expect(flow.notified, isEmpty);
  });

  test('confirmed reset reload prepares exact USDT approval with a separate claim', () async {
    final flow = TokenFlow(db, call: true, approval: true, approvalEnvelope: true,
        reset: true, zeroApproval: false);
    final trade = await flow.create();
    // Seed prior persisted reset evidence: no signing is needed to exercise
    // receipt-driven restart and the actual next preparation/commit boundary.
    await flow.store.claimApproval(trade, 'reset', PegarouteTradeRecord.nonce(), '0x${'b' * 64}');
    facade.receipt = true;
    facade.allowance = BigInt.zero;
    final (send, pending) = tokenSend(flow, trade);
    expect(await send.prepare(), isNotNull);
    expect(pending.commits, 0);
    expect(PegarouteTradeRecord.read(await flow.store.read('order')).approvals['reset']['state'], 'confirmed');
    pending.onCommit = () async {
      final saved = await flow.store.read('order');
      expect(saved.txId, isNull);
      expect(PegarouteTradeRecord.read(saved).approvals['approve']['state'], 'claimed');
      facade.receipt = null;
    };
    await send.commit();
    expect(pending.commits, 1);
    expect((await flow.store.read('order')).txId, isNull);
    expect(flow.notified, isEmpty);
  });

  test('known contract with forged precision is rejected before quoting', () async {
    final flow = TokenFlow(db);
    final forged = Erc20Token(name: 'USD Coin', symbol: 'USDC',
        contractAddress: flow.token.contractAddress, decimal: 18, chainId: 1);
    expect(await flow.provider.fetchRateExact(from: forged, to: CryptoCurrency.xmr, amount: '1.25'), 0);
    expect(flow.quoteAmounts, isEmpty);
    expect(flow.posts, 0);
  });

  test('same-symbol unknown contract never substitutes for the catalog token', () async {
    final unknown = TokenFlow(db, customToken: true);
    await expectLater(unknown.create(), throwsStateError);
    expect(unknown.posts, 0);
    final flow = TokenFlow(db);
    final trade = await flow.create();
    expect((trade.from as Erc20Token).contractAddress, flow.token.contractAddress);
    final (send, _) = tokenSend(flow, trade);
    when(() => send.wallet.balance).thenReturn(ObservableMap.of({
      CryptoCurrency.eth: TestBalance(CryptoCurrency.eth), unknown.token: TestBalance(unknown.token)}));
    expect(await send.prepare(), isNull);
    expect(send.builds, 0);
  });

  for (final column in ['fromDecimals', 'fromTag']) {
    test('raw persisted $column corruption is not hidden by ticker restoration', () async {
      final flow = TokenFlow(db);
      await flow.create();
      await db.update('Trade', {column: column == 'fromDecimals' ? 7 : 'BSC'}, where: 'id = ?', whereArgs: ['order']);
      await expectLater(flow.store.read('order'), throwsFormatException);
    });
  }

  test('confirmed approval reload prepares funding but does not broadcast until separately confirmed', () async {
    final flow = TokenFlow(db, call: true, approval: true);
    final trade = await flow.create();
    final attempt = PegarouteTradeRecord.nonce();
    final approvalHash = '0x${List.filled(64, 'a').join()}';
    final claimed = await flow.store.claimApproval(trade, 'approve', attempt, approvalHash);
    await flow.store.approvalProgress(claimed, 'approve', attempt, approvalHash, 'confirmed');
    facade.allowance = BigInt.from(1250000);
    final (send, pending) = tokenSend(flow, await flow.store.read('order'));
    expect(await send.prepare(), isNotNull);
    expect(pending.commits, 0);
    expect((await flow.store.read('order')).txId, isNull);
    await send.commit();
    expect(pending.commits, 1);
    expect((await flow.store.read('order')).txId, flow.envelope.hash);
    expect(flow.notified, [flow.envelope.hash]);
  });
}
