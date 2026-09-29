import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_record.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_currency_mapper.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pegaroute_flow_test.dart';

class MainnetBitcoin extends CWBitcoin {
  @override
  bool isTestnet(Object wallet) => false;
}
// Zcash is not enabled in the disposable facade. Exercise its authorized
// interface contract with a fake, not a handwritten production implementation.
class CredentialZcash extends Mock implements Zcash {
  @override
  Object createZcashTransactionCredentialsRaw(List<OutputInfo> outputs,
      {required CryptoCurrency currency, required int feeRate}) =>
      (outputs: outputs, currency: currency, feeRate: feeRate);
}
const types = {'BTC': WalletType.bitcoin, 'BCH': WalletType.bitcoinCash,
  'LTC': WalletType.litecoin, 'DOGE': WalletType.dogecoin,
  'TRON': WalletType.tron, 'ZEC': WalletType.zcash};

class FamilyFlow extends DepositFixture {
  FamilyFlow(Database database, String chain) : super(database, source: chain);
  @override
  String get principal => '1.25';
  // Addresses/bytes belong to the fake wallet boundary, not native signing proof.
  @override
  String get sender => 'offline-$source-sender';
  @override
  String get deposit => 'offline-$source-deposit';
  String get token => const PegarouteCurrencyMapper().map(intent.fromCurrency).token;
  String? get memo => const {'BTC', 'BCH', 'LTC', 'DOGE'}.contains(source) ? '1234' : null;
  @override
  Map<String, dynamic> get route => {...super.route, 'memo': memo};
  @override
  Future<Map<String, dynamic>> request(String method, Uri uri, Map<String, String> headers, String? body) async {
    if (uri.path == '/chains') return {'chains': [
      {'id': source, 'name': source, 'chainId': null}, {'id': 'ETH', 'name': 'Ethereum', 'chainId': 1}]};
    if (uri.path == '/tokens' && uri.queryParameters['chain'] == source) {
      return {'chain': source, 'tokens': [{'id': token, 'symbol': intent.fromCurrency.title}]};
    }
    if (uri.path == '/swap') {
      posts++;
      return {'transactionId': 'order', 'status': 'pending', 'providerType': 'api-provider',
        'route': route, 'provider': {'name': 'instaswap', 'referenceId': 'reference'},
        'execution': {'family': source == 'TRON' ? 'tron' : 'utxo',
          'mode': source == 'TRON' ? 'deposit-transfer' : 'payment-with-memo',
          'to': deposit, 'memo': memo, if (source != 'TRON') 'gasRate': null,
          'amount': {'display': principal, 'baseUnits': PegarouteTradeRecord.units(principal, source).toString()}}};
    }
    final result = await super.request(method, uri, headers, body);
    if (uri.path == '/swap/order' && method == 'GET') (result['input'] as Map)['token'] = token;
    return result;
  }
}
class FamilyPending extends TestPending {
  FamilyPending(FamilyFlow flow) : deferred = flow.source == 'ZEC', super(flow.intent.fromCurrency, flow.principal);
  final bool deferred;
  @override
  String get hex => deferred ? '' : 'deadbeef';
  @override
  String get id => deferred && commits == 0 ? '' : xmrHash;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  setUpAll(() { registerFallbackValue(WalletType.ethereum); registerFallbackValue(Object()); S.current = const S(); });
  setUp(() async {
    db = await openDepositDb(); bitcoin = MainnetBitcoin(); tron = CWTron(); zcash = CredentialZcash(); monero = TestMonero();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async { await db.close(); sqlite.db = null; bitcoin = null; tron = null; zcash = null; });

  for (final chain in types.keys) {
    test('$chain actual provider/SendViewModel and facade credentials; durable native claim before fake broadcast', () async {
      final flow = FamilyFlow(db, chain);
      final trade = await flow.create();
      final send = SendFixture(flow, trade);
      final pending = FamilyPending(flow);
      when(() => send.wallet.type).thenReturn(types[chain]!);
      when(() => send.settings.getPriority(any(), chainId: any(named: 'chainId')))
          .thenReturn(bitcoin!.getMediumTransactionPriority());
      send.model.outputs.single.memo = flow.memo ?? '';
      when(() => send.wallet.createTransaction(any())).thenAnswer((invocation) async {
        send.builds++;
        final dynamic credentials = invocation.positionalArguments.single;
        final outputs = (credentials.outputs as List).cast<OutputInfo>();
        expect(outputs.single.address, flow.deposit);
        expect(outputs.single.cryptoAmount.toString(), flow.principal);
        expect(outputs.single.sendAll, false);
        if (flow.memo != null) expect(outputs.single.memo, '31323334');
        return pending;
      });
      expect(await send.prepare(), isNotNull);
      pending.onCommit = () async {
        final record = PegarouteTradeRecord.read(await flow.store.read('order'));
        expect(record.attempt, isNotNull);
        if (chain == 'ZEC') expect(record.proposedHash, isNull);
      };
      await send.commit();
      expect(pending.commits, 1);
      expect((await flow.store.read('order')).txId, xmrHash);
      expect(flow.notified, [xmrHash]);
      expect(send.model.state, isA<TransactionCommitted>());
      expect(await send.prepare(), isNull);
      expect(pending.commits, 1);
    });
  }
}
