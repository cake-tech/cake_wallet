import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_receive_page_option.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/node.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final _seed = Uint8List.fromList(List<int>.generate(64, (i) => i));
final _master = Bip32Slip10Secp256k1.fromSeed(_seed);
final _p2wpkhHd = _master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
final _p2pkhHd = _master.derivePath("m/44'/0'/0'/0") as Bip32Slip10Secp256k1;

final _p2wpkhRecord = BitcoinAddressRecord(
  generateP2WPKHAddress(hd: _p2wpkhHd, network: BitcoinNetwork.mainnet, index: 0),
  index: 0,
  type: SegwitAddresType.p2wpkh,
  network: BitcoinNetwork.mainnet,
);

/// A legacy address the wallet used before optional types could be turned off.
BitcoinAddressRecord _usedP2pkhRecord() => BitcoinAddressRecord(
      generateP2PKHAddress(hd: _p2pkhHd, network: BitcoinNetwork.mainnet, index: 0),
      index: 0,
      type: P2pkhAddressType.p2pkh,
      network: BitcoinNetwork.mainnet,
      isUsed: true,
      txCount: 1,
      balance: 5000,
    );

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _EmptyUnspentsBox implements Box<UnspentCoinsInfo> {
  @override
  Iterable<UnspentCoinsInfo> get values => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Addresses extends BitcoinWalletAddresses {
  _Addresses(super.walletInfo, ElectrumWallet wallet, List<BitcoinAddressRecord> initialAddresses)
      : super(
          mainHdByTypeAndAccount: wallet.mainHdByTypeAndAccount,
          sideHdByTypeAndAccount: wallet.sideHdByTypeAndAccount,
          accountIndexes: [0],
          currentAccountIndex: 0,
          legacyMainHd: wallet.mainHd,
          legacySideHd: wallet.sideHd,
          network: BitcoinNetwork.mainnet,
          isHardwareWallet: false,
          payjoinManager: _NoPayjoin(),
          initialAddresses: initialAddresses,
          enabledOptionalAddressTypes: wallet.enabledOptionalAddressTypes,
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

class _Wallet extends ElectrumWallet {
  _Wallet(WalletInfo walletInfo, {Set<BitcoinAddressType>? enabledOptionalAddressTypes})
      : super(
          password: "",
          walletInfo: walletInfo,
          derivationInfo: DerivationInfo(
            derivationType: DerivationType.bip39,
            derivationPath: "m/84'/0'/0'",
          ),
          unspentCoinsInfo: _EmptyUnspentsBox(),
          network: BitcoinNetwork.mainnet,
          encryptionFileUtils: encryptionFileUtilsFor(false),
          seedBytes: _seed,
          currency: CryptoCurrency.btc,
          enabledOptionalAddressTypes: enabledOptionalAddressTypes,
        );

  @override
  Future<void> save() async {}
}

/// Electrum server stand-in that records every script hash the wallet asks about.
class _FakeNode {
  _FakeNode._(this._server);

  final ServerSocket _server;
  final requestedScriptHashes = <String>{};

  static Future<_FakeNode> start() async {
    final node = _FakeNode._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
    node._server.listen((c) {
      c.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          final request = json.decode(line);
          if (request is! Map) return;

          final method = request["method"] as String;
          final params = request["params"] as List? ?? [];
          if (method.startsWith("blockchain.scripthash.") && params.isNotEmpty) {
            node.requestedScriptHashes.add(params.first as String);
          }

          final result = switch (method) {
            "blockchain.headers.subscribe" => '{"height":800000}',
            "blockchain.scripthash.get_history" || "blockchain.scripthash.listunspent" => "[]",
            "blockchain.scripthash.get_balance" => '{"confirmed":0,"unconfirmed":0}',
            _ => "null",
          };
          c.write('{"jsonrpc":"2.0","result":$result,"id":${json.encode(request['id'])}}\n');
        },
        onDone: () => c.destroy(),
        onError: (_) {},
      );
    });
    return node;
  }

  int get port => _server.port;

  Future<void> close() => _server.close();
}

WalletInfo _walletInfo() => WalletInfo.external(
      id: "optional_address_types_test",
      name: "optional_address_types_test",
      type: WalletType.bitcoin,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "",
    );

_Wallet _wallet(
  List<BitcoinAddressRecord> initialAddresses, {
  Set<BitcoinAddressType>? enabledOptionalAddressTypes,
}) {
  final walletInfo = _walletInfo();
  final wallet = _Wallet(walletInfo, enabledOptionalAddressTypes: enabledOptionalAddressTypes);
  wallet.walletAddresses = _Addresses(walletInfo, wallet, initialAddresses);
  return wallet;
}

Future<void> _waitFor(bool Function() done, Duration max) async {
  final end = DateTime.now().add(max);
  while (!done() && DateTime.now().isBefore(end)) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Runs every path that asks the node about the wallet's addresses.
Future<void> _syncAgainst(_FakeNode node, ElectrumWallet wallet) async {
  await wallet.connectToNode(
    node: Node(uri: "127.0.0.1:${node.port}", type: WalletType.bitcoin, useSSL: false),
  );
  await _waitFor(
    () => wallet.syncStatus is ConnectedSyncStatus && wallet.electrumClient.isConnected,
    const Duration(seconds: 8),
  );
  await wallet.subscribeForUpdates();
  await wallet.fetchTransactions();
  await wallet.updateAllUnspents();
  await wallet.fetchBalances();
  await wallet.checkNodeHealth();
  await Future.delayed(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db!.execute(
      "CREATE TABLE walletInfoAddress "
      "(walletInfoAddressId INTEGER PRIMARY KEY, walletInfoId INTEGER, type INTEGER, "
      "address TEXT)",
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CakeTor.instance = CakeTorDisabled();
  });

  test("a wallet with no saved choice derives HDs for P2WPKH and P2TR only", () {
    final wallet = _wallet([_p2wpkhRecord]);

    expect(
      wallet.mainHdByTypeAndAccount[0]!.keys,
      unorderedEquals([SegwitAddresType.p2wpkh, SegwitAddresType.p2tr]),
    );
    expect(
      wallet.sideHdByTypeAndAccount[0]!.keys,
      unorderedEquals([SegwitAddresType.p2wpkh, SegwitAddresType.p2tr]),
    );
  });

  test("init generates no addresses for disabled types, not even on the legacy derivation",
      () async {
    final wallet = _wallet([_p2wpkhRecord]);

    await wallet.walletAddresses.init();

    final types = wallet.walletAddresses.allAddresses.map((record) => record.type).toSet();
    expect(types, unorderedEquals([SegwitAddresType.p2wpkh, SegwitAddresType.p2tr]));
  });

  test("used addresses of a disabled type stay saved but out of the active set", () {
    final p2pkh = _usedP2pkhRecord();
    final wallet = _wallet([_p2wpkhRecord, p2pkh]);

    expect(wallet.walletAddresses.allAddresses, contains(p2pkh));
    expect(wallet.walletAddresses.activeAddresses, isNot(contains(p2pkh)));
    expect(
        wallet.walletAddresses.receivePageOptions, isNot(contains(BitcoinReceivePageOption.p2pkh)));
  });

  test("a saved page type that is disabled falls back to P2WPKH", () {
    final walletInfo = _walletInfo()..addressPageType = P2pkhAddressType.p2pkh.toString();
    final wallet = _Wallet(walletInfo);
    wallet.walletAddresses = _Addresses(walletInfo, wallet, [_p2wpkhRecord]);

    expect(wallet.walletAddresses.addressPageType, SegwitAddresType.p2wpkh);
  });

  test(
    "syncing never asks the node about a disabled type, even one the wallet used",
    () async {
      final node = await _FakeNode.start();
      final p2pkh = _usedP2pkhRecord();
      final wallet = _wallet([_p2wpkhRecord, p2pkh]);

      await _syncAgainst(node, wallet);

      expect(node.requestedScriptHashes, contains(_p2wpkhRecord.getScriptHash(wallet.network)));
      expect(node.requestedScriptHashes, isNot(contains(p2pkh.getScriptHash(wallet.network))));
      expect(
        wallet.walletAddresses.allAddresses.where((r) => r.type == P2pkhAddressType.p2pkh),
        [p2pkh],
      );
      await wallet.close();
      await node.close();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    "enabling a type in the settings derives and syncs it; disabling stops it again",
    () async {
      final node = await _FakeNode.start();
      final p2pkh = _usedP2pkhRecord();
      final wallet = _wallet([_p2wpkhRecord, p2pkh]);
      await _syncAgainst(node, wallet);

      await wallet.setAddressTypeEnabled(P2pkhAddressType.p2pkh, willEnable: true);

      expect(wallet.mainHdByTypeAndAccount[0], contains(P2pkhAddressType.p2pkh));
      expect(node.requestedScriptHashes, contains(p2pkh.getScriptHash(wallet.network)));
      expect(
        wallet.walletAddresses.receivePageOptions,
        contains(BitcoinReceivePageOption.p2pkh),
      );

      await wallet.setAddressTypeEnabled(P2pkhAddressType.p2pkh, willEnable: false);
      node.requestedScriptHashes.clear();
      await _syncAgainst(node, wallet);

      expect(wallet.mainHdByTypeAndAccount[0], isNot(contains(P2pkhAddressType.p2pkh)));
      expect(node.requestedScriptHashes, isNot(contains(p2pkh.getScriptHash(wallet.network))));
      await wallet.close();
      await node.close();
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test("a saved choice keeps the type enabled after reopening", () {
    final wallet = _wallet(
      [_p2wpkhRecord],
      enabledOptionalAddressTypes: {P2pkhAddressType.p2pkh},
    );

    expect(wallet.mainHdByTypeAndAccount[0], contains(P2pkhAddressType.p2pkh));
    final saved = json.decode(wallet.toJSON())["enabled_optional_address_types"];
    expect(saved, [P2pkhAddressType.p2pkh.value]);
  });

  test("other coins have no optional types", () {
    expect(
      isAddressTypeEnabledFor(WalletType.bitcoinCash, P2pkhAddressType.p2pkh,
          enabledOptionalAddressTypes: {}),
      isTrue,
    );
  });
}
