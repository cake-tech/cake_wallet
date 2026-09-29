import 'dart:convert';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_record.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_solana_wire.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/solana_serialized_transaction_credentials.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/db/sqlite.dart' as sqlite;
// Offline test exercises the real core preparation helper with a replay key.
// ignore: cw_custom_lints/no_restricted_imports_in_lib
import 'package:cw_solana/prepare_serialized_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pegaroute_flow_test.dart';

// Published SDK test vector, on_chain 096865a8, test/solana/tests/system/
// compiled_message_v0_test.dart::_transfer. No keys or signing computation.
const signedHex = '01291275a7bf5a77b7f6296d7ea2eeea174179f47b5ebd87988638fc7a750b7c5035cdc922c1a77943fa760bc2de16d870b0b7ff46ae8dcac03df503e175074e0580010001033bb809f4c65f4bd79708f7b52b94f2e17a878c779d420c29d728844a83eec5bf807e1b63e7c241c72448e8f9f05e65d421ea40ceae40f47ca347f7d79c38d0e60000000000000000000000000000000000000000000000000000000000000000e66f07ae6ad93c9ea60272507db1a2d2089bbb67540ff6e291f98bcf5df4bc8901020200010c0200000040420f000000000000';
final signedBytes = BytesUtils.fromHexString(signedHex);
final vector = SolanaTransaction.deserialize(signedBytes, verifySignatures: true);
final unsignedBytes = List<int>.from(signedBytes)..fillRange(1, 65, 0);
final signature = Base58Encoder.encode(vector.signatures.first);

class ReplayKey extends Mock implements SolanaPrivateKey {
  @override
  SolanaPublicKey publicKey() => SolanaPublicKey.fromBytes(BytesUtils.fromHexString(
      '3bb809f4c65f4bd79708f7b52b94f2e17a878c779d420c29d728844a83eec5bf'));
  @override
  List<int> sign(List<int> message) {
    expect(message, vector.serializeMessage());
    return vector.signatures.first; // Replay only; no private key operation.
  }
}
class ReplayRpc implements SolanaRPC {
  String genesis = '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d';
  int sends = 0;
  bool wrongId = false;
  Future<void> Function()? beforeSend;
  @override
  Future<T> request<T>(SolanaRPCRequest<T> request, [Duration? timeout]) async {
    if (request is SolanaRPCGetGenesisHash) return genesis as T;
    if (request is SolanaRPCGetFeeForMessage) return BigInt.from(5000) as T;
    final send = request as SolanaRPCSendTransaction;
    expect(send.skipPreflight, false);
    expect(Base58Decoder.decode(send.encodedTransaction), signedBytes);
    await beforeSend?.call();
    sends++;
    return (wrongId ? 'different-id' : signature) as T;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
class SolanaFlow extends DepositFixture {
  SolanaFlow(super.database, this.encoding) : super(source: 'SOL');
  final String encoding;
  @override
  String get principal => '0.001';
  @override
  String get sender => ReplayKey().publicKey().toAddress().address;
  @override
  String get deposit => payout; // Supplied execution has no deposit address.
  @override
  Map<String, dynamic> get route => {...super.route, 'provider': 'openocean'};
  @override
  Future<Map<String, dynamic>> request(String method, Uri uri, Map<String, String> headers, String? body) async {
    if (uri.path == '/chains') return {'chains': [
      {'id': 'SOL', 'name': 'Solana', 'chainId': null}, {'id': 'ETH', 'name': 'Ethereum', 'chainId': 1}]};
    if (uri.path == '/swap') {
      posts++;
      return {'transactionId': 'order', 'status': 'pending', 'providerType': 'api-provider',
        'provider': {'name': 'openocean', 'referenceId': 'reference'}, 'route': route,
        'execution': {'family': 'solana', 'mode': 'serialized-tx', 'encoding': encoding,
          'serializedTransaction': encoding == 'base64' ? base64Encode(unsignedBytes) : Base58Encoder.encode(unsignedBytes),
          'minOut': null}};
    }
    return super.request(method, uri, headers, body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  setUpAll(() { registerFallbackValue(WalletType.ethereum); registerFallbackValue(Object()); S.current = const S(); });
  setUp(() async {
    db = await openDepositDb(); solana = CWSolana(); monero = TestMonero();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async { await db.close(); sqlite.db = null; solana = null; });
  for (final encoding in ['base58', 'base64']) {
    test('$encoding supplied Solana real provider, SendViewModel, core preparation and claimed commit', () async {
      final flow = SolanaFlow(db, encoding);
      final trade = await flow.create();
      final send = SendFixture(flow, trade);
      final rpc = ReplayRpc();
      when(() => send.wallet.type).thenReturn(WalletType.solana);
      when(() => send.wallet.createTransaction(any())).thenAnswer((call) async {
        send.builds++;
        final credentials = call.positionalArguments.single as SolanaSerializedTransactionCredentials;
        expect(Base58Decoder.decode(credentials.transactionBase58), unsignedBytes);
        return prepareSerializedSolanaTransaction(credentials: credentials, privateKey: ReplayKey(),
            provider: rpc, isCurrentProvider: () => true, nativeBalance: Money.parse('1', CryptoCurrency.sol));
      });
      expect(await send.prepare(), isNotNull);
      expect(rpc.sends, 0);
      rpc.beforeSend = () async {
        expect(PegarouteTradeRecord.read(await flow.store.read('order')).attempt, isNotNull);
      };
      await send.commit();
      expect(rpc.sends, 1);
      expect((await flow.store.read('order')).txId, signature);
      expect(flow.notified, [signature]);
      expect(send.model.state, isA<TransactionCommitted>());
      expect(await send.prepare(), isNull);
      expect(rpc.sends, 1);
    });
  }
  test('core supplied preparation rejects non-mainnet and insufficient SOL without signing', () async {
    final credentials = SolanaSerializedTransactionCredentials(transactionBase58: Base58Encoder.encode(unsignedBytes),
        amount: Money.parse('0.001', CryptoCurrency.sol), destinationAddress: ethAddress);
    final rpc = ReplayRpc()..genesis = 'testnet';
    Future<void> prepare(Money balance) async {
      await prepareSerializedSolanaTransaction(credentials: credentials, privateKey: ReplayKey(),
          provider: rpc, isCurrentProvider: () => true, nativeBalance: balance);
    }
    await expectLater(prepare(Money.parse('1', CryptoCurrency.sol)), throwsStateError);
    rpc.genesis = '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d';
    await expectLater(prepare(Money.parse('0.001', CryptoCurrency.sol)), throwsStateError);
    expect(rpc.sends, 0);
    expect(() => decodePegarouteSolanaTransaction(base64Encode(unsignedBytes), 'hex'), throwsFormatException);
  });
}
