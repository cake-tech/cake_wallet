import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart' show BytesUtils, QuickCrypto;
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/db/sqlite.dart' as storage;
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_tron/tron_balance.dart';
import 'package:cw_tron/tron_client.dart';
import 'package:cw_tron/hardware/tron_ledger_app.dart';
import 'package:cw_tron/hardware/tron_ledger_service.dart';
import 'package:cw_tron/tron_transaction_credentials.dart';
import 'package:cw_tron/tron_transaction_info.dart';
import 'package:cw_tron/tron_wallet_creation_credentials.dart';
import 'package:cw_tron/tron_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

class _OfflineClient extends TronClient {
  _OfflineClient() : super(provider: TronProvider(_Rpc()), broadcast: _recordBroadcast);
  static int broadcasts = 0;
  static Future<String> _recordBroadcast(Uint8List bytes) async {
    broadcasts++;
    return 'accepted';
  }

  final seenAddresses = <String>[];

  @override
  Future<BigInt> getBalance(TronAddress address, {bool throwOnError = false}) async {
    seenAddresses.add(address.toAddress());
    return BigInt.from(1234567);
  }

  @override
  Future<TronBalance> fetchTronTokenBalances(String address, String contract,
      {bool throwOnError = false, required Currency currency}) async {
    seenAddresses.add(address);
    return TronBalance(Money.zero(currency));
  }
}

class _Rpc with TronServiceProvider {
  @override
  String get url => 'https://example.invalid';

  @override
  Future<Map<String, dynamic>> get(TronRequestDetails params, [Duration? timeout]) =>
      post(params, timeout);

  @override
  Future<Map<String, dynamic>> post(TronRequestDetails params, [Duration? timeout]) async {
    if (params.method.uri == 'wallet/getnowblock') {
      return {
        'blockID': '00',
        'block_header': {
          'raw_data': {
            'number': 100,
            'version': 1,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        }
      };
    }
    throw StateError('Unexpected RPC request: ${params.method.uri}');
  }
}

class _Device implements LedgerDevice {
  @override
  String get id => 'test-ledger';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RejectingManager implements ConnectionManager {
  _RejectingManager({required this.disconnected});
  final bool disconnected;
  int calls = 0;

  @override
  ConnectionType get connectionType => ConnectionType.ble;

  @override
  Stream<BleConnectionState> deviceStateChanges(String deviceId) => const Stream.empty();

  @override
  Future<T> sendRawOperation<T>(
      LedgerDevice device, LedgerRawOperation<T> operation, LedgerTransformer? transformer) async {
    await operation.write(ByteDataWriter());
    calls++;
    if (disconnected) throw StateError('Device disconnected');
    final reader = ByteDataReader()..add(Uint8List.fromList([0x69, 0x85]));
    return operation.read(reader);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AddressManager implements ConnectionManager {
  _AddressManager(this.key);
  final TronPublicKey key;
  final calls = <Uint8List>[];

  @override
  ConnectionType get connectionType => ConnectionType.ble;

  @override
  Stream<BleConnectionState> deviceStateChanges(String deviceId) => const Stream.empty();

  @override
  Future<T> sendRawOperation<T>(
      LedgerDevice device, LedgerRawOperation<T> operation, LedgerTransformer? transformer) async {
    calls.addAll(await operation.write(ByteDataWriter()));
    final address = key.toAddress().toAddress();
    final response = [
      65,
      ...key.toBytes(PubKeyModes.uncompressed),
      34,
      ...address.codeUnits,
      0x90,
      0,
    ];
    return operation.read(ByteDataReader()..add(Uint8List.fromList(response)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedManager implements ConnectionManager {
  _DelayedManager(this.key);
  final TronPrivateKey key;
  final states = StreamController<BleConnectionState>.broadcast(sync: true);
  final sent = Completer<void>();
  final release = Completer<void>();
  final settled = Completer<void>();

  @override
  ConnectionType get connectionType => ConnectionType.ble;

  @override
  Stream<BleConnectionState> deviceStateChanges(String deviceId) => states.stream;

  @override
  Future<T> sendRawOperation<T>(
      LedgerDevice device, LedgerRawOperation<T> operation, LedgerTransformer? transformer) async {
    final packet = (await operation.write(ByteDataWriter())).single;
    expect(packet[1], 0x04);
    expect(packet[2], 0x10);
    final raw = packet.sublist(26);
    sent.complete();
    try {
      await release.future;
      final signature = Uint8List.fromList(key.sign(raw))..[64] -= 27;
      final signer = TronPublicKey.fromPersonalSignature(
        QuickCrypto.sha256Hash(raw),
        BytesUtils.toHexString(signature),
        hashMessage: false,
      );
      expect(signer!.toAddress().toAddress(), key.publicKey().toAddress().toAddress());
      return await operation.read(
        ByteDataReader()..add(Uint8List.fromList([...signature, 0x90, 0x00])),
      );
    } finally {
      settled.complete();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late PathProviderPlatform previousPaths;

  setUpAll(() async {
    root = Directory('test/.tron-ledger-wallet-fixture-$pid');
    await root.create(recursive: true);
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.absolute.path);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await storage.initDb();
    SharedPreferences.setMockInitialValues({'use_trongrid': false});
  });

  tearDownAll(() async {
    await storage.db!.close();
    PathProviderPlatform.instance = previousPaths;
    await root.delete(recursive: true);
  });

  for (final account in [0, 1]) {
    test('restores account $account offline and rejects a late BLE signing response', () async {
      final name = 'ledger-account-$account';
      final path = "m/44'/195'/$account'/0/0";
      final key = TronPrivateKey((account + 1).toRadixString(16).padLeft(64, '0'));
      final publicKey = key.publicKey();
      final address = publicKey.toAddress().toAddress();
      final derivation = DerivationInfo(derivationPath: path, derivationType: DerivationType.bip39);
      await derivation.save();
      final info = WalletInfo.external(
        id: name,
        name: name,
        type: WalletType.tron,
        isRecovery: true,
        restoreHeight: 0,
        date: DateTime(2024),
        dirPath: await pathForWalletDir(name: name, type: WalletType.tron),
        path: await pathForWallet(name: name, type: WalletType.tron),
        address: '',
        derivationInfoId: derivation.id,
        hardwareWalletType: HardwareWalletType.ledger,
      );
      final client = _OfflineClient();
      final service = TronWalletService(client: client, isDirect: false);
      final credentials = TronRestoreWalletFromHardware(
        name: name,
        password: 'ledger-test-password',
        walletInfo: info,
        accountData: HardwareAccountData(
          address: address,
          accountIndex: account,
          derivationPath: path,
        ),
      )..hardwareWalletType = HardwareWalletType.ledger;

      final wallet = await service.restoreFromHardwareWallet(credentials);
      expect(wallet.seed, isNull);
      expect(wallet.privateKey, isNull);
      expect(wallet.canSignMessages, isFalse);
      await expectLater(wallet.signMessage('Unicode: 🧁'), throwsUnsupportedError);
      wallet.balance[CryptoCurrency.trx] = TronBalance(Money(BigInt.from(42), CryptoCurrency.trx));
      wallet.transactionHistory.addOne(TronTransactionInfo(
        id: 'persisted',
        amount: Money(BigInt.one, CryptoCurrency.trx),
        fee: Money.zero(CryptoCurrency.trx),
        direction: TransactionDirection.incoming,
        blockTime: DateTime(2024),
        to: address,
        from: address,
        isPending: false,
      ));
      await wallet.save();
      expect(await WalletKeysFile.hasKeysFile(name, WalletType.tron), isFalse);

      final saved = await WalletInfo.get(name, WalletType.tron);
      expect(saved, isNotNull);
      expect((await saved!.getDerivationInfo()).derivationPath, path);
      final reopened = await service.openWallet(name, 'ledger-test-password');
      expect(reopened.walletAddresses.address, address);
      expect(reopened.seed, isNull);
      expect(reopened.privateKey, isNull);
      expect(reopened.balance[CryptoCurrency.trx]!.balance.amount, BigInt.from(42));
      expect(reopened.transactionHistory.transactions, contains('persisted'));
      expect(await WalletKeysFile.hasKeysFile(name, WalletType.tron), isFalse);
      final walletPath = await pathForWallet(name: name, type: WalletType.tron);
      expect(File('$walletPath.keys').existsSync(), isFalse);
      expect(File('$walletPath.keys.backup').existsSync(), isFalse);

      await reopened.startSync();
      expect(reopened.balance[CryptoCurrency.trx]!.balance.amount, BigInt.from(1234567));
      expect(client.seenAddresses, isNotEmpty);
      expect(client.seenAddresses, everyElement(address));
      expect(reopened.transactionHistory.transactions, contains('persisted'));

      final addressManager = _AddressManager(publicKey);
      reopened.setHardwareWalletService(
        TronLedgerService(LedgerConnection(addressManager, _Device())),
      );
      await reopened.verifyHardwareAddress();
      expect(addressManager.calls.single[1], 0x02);
      expect(addressManager.calls.single[2], 1);
      expect(addressManager.calls.single[17], account);
      final wrongKey = TronPrivateKey((account + 3).toRadixString(16).padLeft(64, '0')).publicKey();
      reopened.setHardwareWalletService(
        TronLedgerService(LedgerConnection(_AddressManager(wrongKey), _Device())),
      );
      await expectLater(reopened.verifyHardwareAddress(), throwsA(isA<TronLedgerException>()));

      final output = OutputInfo(
        address: account == 0
            ? 'TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7'
            : 'TJRabPrwbZy45sbavfcjinPJC18kjpRTv8',
        sendAll: false,
        isParsedAddress: false,
        cryptoAmount: Money(BigInt.from(100000), CryptoCurrency.trx),
      );
      final transaction = TronTransactionCredentials([output], currency: CryptoCurrency.trx);
      for (final disconnected in [false, true]) {
        _OfflineClient.broadcasts = 0;
        final manager = _RejectingManager(disconnected: disconnected);
        reopened.setHardwareWalletService(TronLedgerService(LedgerConnection(manager, _Device())));
        await expectLater(
          reopened.createTransaction(transaction),
          throwsA(disconnected ? isA<StateError>() : isA<TronLedgerException>()),
        );
        expect(manager.calls, greaterThan(0));
        expect(_OfflineClient.broadcasts, 0);
      }
      _OfflineClient.broadcasts = 0;
      final delayedManager = _DelayedManager(key);
      reopened.setHardwareWalletService(
        TronLedgerService(LedgerConnection(delayedManager, _Device())),
      );
      final pending = reopened.createTransaction(transaction);
      await delayedManager.sent.future.timeout(const Duration(seconds: 2));
      final failure = expectLater(pending, throwsA(isA<ConnectionLostException>()));
      try {
        delayedManager.states.add(BleConnectionState.disconnected);
        await failure.timeout(const Duration(seconds: 2));
        expect(_OfflineClient.broadcasts, 0);
      } finally {
        delayedManager.release.complete();
        await delayedManager.settled.future.timeout(const Duration(seconds: 2));
        await delayedManager.states.close();
      }
      await Future<void>.delayed(Duration.zero);
      expect(_OfflineClient.broadcasts, 0);
      reopened.clearHardwareWalletService();
      await expectLater(reopened.createTransaction(transaction), throwsStateError);
      expect(_OfflineClient.broadcasts, 0);
    });
  }
}
