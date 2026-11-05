import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:blockchain_utils/bip/address/p2pkh_addr.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/new-ui/pages/verify_ledger_address.dart";
import "package:cake_wallet/view_model/send/tron_output_data.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart" as storage;
import "package:cw_core/hardware/hardware_account_data.dart";
import "package:cw_core/pathForWallet.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus_dart.dart";
import "package:on_chain/tron/tron.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

class _Manager implements ConnectionManager {
  _Manager(this.publicKey);
  TronPublicKey publicKey;
  final calls = <Uint8List>[];

  @override
  ConnectionType get connectionType => ConnectionType.ble;

  @override
  Stream<BleConnectionState> deviceStateChanges(String deviceId) => const Stream.empty();

  @override
  Future<T> sendRawOperation<T>(
      LedgerDevice device, LedgerRawOperation<T> operation, LedgerTransformer? transformer) async {
    calls.addAll(await operation.write(ByteDataWriter()));
    final address = publicKey.toAddress().toAddress();
    final response = [
      65,
      ...publicKey.toBytes(PubKeyModes.uncompressed),
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

class _Output implements TronOutputData {
  @override
  String get address => "recipient";
  @override
  Money get cryptoAmountMoney => Money(BigInt.from(123), CryptoCurrency.trx);
  @override
  String get extractedAddress => "parsed-recipient";
  @override
  String get fiatAmount => "5";
  @override
  bool get isParsedAddress => true;
  @override
  String get memo => "memo";
  @override
  String get note => "note";
  @override
  bool get sendAll => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late PathProviderPlatform oldPaths;

  setUpAll(() async {
    root = Directory("test/.tron-bridge-fixture-$pid");
    await root.create(recursive: true);
    oldPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.absolute.path);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await storage.initDb();
  });

  tearDownAll(() async {
    await storage.db!.close();
    PathProviderPlatform.instance = oldPaths;
    await root.delete(recursive: true);
  });

  test("bridge attaches, verifies the saved account on device, and clears the service", () async {
    const name = "bridge-ledger";
    const path = "m/44'/195'/1'/0/0";
    final key = TronPrivateKey("1".padLeft(64, "0")).publicKey();
    final address = key.toAddress().toAddress();
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
      address: "",
      derivationInfoId: derivation.id,
      hardwareWalletType: HardwareWalletType.ledger,
    );
    final credentials = tron!.createTronHardwareWalletCredentials(
      name: name,
      accountData: HardwareAccountData(address: address, accountIndex: 1, derivationPath: path),
    )
      ..password = "bridge-test-password"
      ..walletInfo = info
      ..hardwareWalletType = HardwareWalletType.ledger;
    final wallet =
        await tron!.createTronWalletService(false).restoreFromHardwareWallet(credentials);
    final manager = _Manager(key);
    final device =
        LedgerDevice.ble(id: "ledger", name: "ledger", deviceInfo: LedgerDeviceType.stax);
    final service = tron!.getLedgerHardwareWalletService(LedgerConnection(manager, device));
    await tron!.setHardwareWalletService(wallet, service);
    final connect = Completer<bool>();
    var isCurrent = true;
    final verification = verifyLedgerAddress(
      wallet: wallet,
      ensureConnected: () => connect.future,
      isCurrentWallet: () => isCurrent,
      verifyAddress: tron!.verifyHardwareAddress,
    );
    expect(manager.calls, isEmpty);
    connect.complete(true);
    await verification;
    expect(manager.calls.single[1], 0x02);
    expect(manager.calls.single[2], 1);
    expect(manager.calls.single[17], 1);

    await verifyLedgerAddress(
      wallet: wallet,
      ensureConnected: () async => false,
      isCurrentWallet: () => isCurrent,
      verifyAddress: tron!.verifyHardwareAddress,
    );
    final staleConnect = Completer<bool>();
    final staleVerification = verifyLedgerAddress(
      wallet: wallet,
      ensureConnected: () => staleConnect.future,
      isCurrentWallet: () => isCurrent,
      verifyAddress: tron!.verifyHardwareAddress,
    );
    isCurrent = false;
    staleConnect.complete(true);
    await staleVerification;
    expect(manager.calls, hasLength(1));

    manager.publicKey = TronPrivateKey("2".padLeft(64, "0")).publicKey();
    isCurrent = true;
    await expectLater(
      verifyLedgerAddress(
        wallet: wallet,
        ensureConnected: () async => true,
        isCurrentWallet: () => isCurrent,
        verifyAddress: tron!.verifyHardwareAddress,
      ),
      throwsA(isA<Exception>()),
    );
    tron!.clearHardwareWalletService(wallet);
    await expectLater(tron!.verifyHardwareAddress(wallet), throwsStateError);
  });

  test("software send bridge preserves output fields", () {
    final dynamic credentials =
        tron!.createTronTransactionCredentials([_Output()], currency: CryptoCurrency.trx);
    final output = credentials.outputs.single;
    expect(output.address, "recipient");
    expect(output.extractedAddress, "parsed-recipient");
    expect(output.cryptoAmount.amount, BigInt.from(123));
    expect(output.fiatAmount, "5");
    expect(output.note, "note");
    expect(output.memo, "memo");
    expect(output.sendAll, isFalse);
    expect(output.isParsedAddress, isTrue);
  });
}
