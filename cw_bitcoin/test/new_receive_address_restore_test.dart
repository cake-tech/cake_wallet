// End to end: a payment to an address "new address" hands out is found when the seed is restored.
// Runs the real ElectrumWallet, BitcoinWalletAddresses and ElectrumClient against a local stand-in
// Electrum server. A sync is the discovery part of ElectrumWalletBase.startSync.
import "dart:convert";
import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/node.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/utils/bip39_seed.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// The BIP84 test vector mnemonic (https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki).
const String _mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon "
    "abandon abandon abandon about";
final Uint8List _seed = bip39MnemonicToSeed(_mnemonic);
final Bip32Slip10Secp256k1 _receiveHd =
    Bip32Slip10Secp256k1.fromSeed(_seed).derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;

String _receive(int index) =>
    generateP2WPKHAddress(hd: _receiveHd, index: index, network: BitcoinNetwork.mainnet);

String _scriptHash(String address) => BitcoinAddressRecord(
      address,
      index: 0,
      type: SegwitAddresType.p2wpkh,
      network: BitcoinNetwork.mainnet,
    ).getScriptHash(BitcoinNetwork.mainnet);

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoUnspentsBox implements Box<UnspentCoinsInfo> {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Built with the arguments BitcoinWalletBase passes.
class _Addresses extends BitcoinWalletAddresses {
  _Addresses(super.walletInfo, ElectrumWallet wallet)
      : super(
          mainHdByTypeAndAccount: wallet.mainHdByTypeAndAccount,
          sideHdByTypeAndAccount: wallet.sideHdByTypeAndAccount,
          accountIndexes: [wallet.currentAccountIndex],
          currentAccountIndex: wallet.currentAccountIndex,
          legacyMainHd: wallet.mainHd,
          legacySideHd: wallet.sideHd,
          network: BitcoinNetwork.mainnet,
          masterHd: Bip32Slip10Secp256k1.fromSeed(_seed),
          isHardwareWallet: false,
          payjoinManager: _NoPayjoin(),
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

/// Electrum server stand-in: newline-delimited JSON-RPC, single and batch requests. The receive
/// addresses at [usedReceiveIndexes] have history.
class _FakeNode {
  _FakeNode._(this._server, this._usedScriptHashes, this._supportsBatch);

  final ServerSocket _server;
  final Set<String> _usedScriptHashes;
  final bool _supportsBatch;

  static Future<_FakeNode> start(Set<int> usedReceiveIndexes, {required bool batch}) async {
    final _FakeNode node = _FakeNode._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
      {for (final index in usedReceiveIndexes) _scriptHash(_receive(index))},
      batch,
    );
    node._server.listen((c) {
      c.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          final dynamic request = json.decode(line);
          if (request is List) {
            final List<Map<String, dynamic>> responses = [
              for (final r in request.cast<Map<String, dynamic>>())
                {
                  "jsonrpc": "2.0",
                  // checkIfBatchSupported reads a result with an "error" key as "no batches".
                  "result": node._supportsBatch ? node._answer(r) : {"error": "no batches"},
                  "id": r["id"],
                },
            ];
            c.write("${json.encode(responses)}\n");
          } else if (request is Map<String, dynamic>) {
            final Map<String, dynamic> response = {
              "jsonrpc": "2.0",
              "result": node._answer(request),
              "id": request["id"],
            };
            c.write("${json.encode(response)}\n");
          }
        },
        onDone: () => c.destroy(),
        onError: (_) {},
      );
    });
    return node;
  }

  Object? _answer(Map<String, dynamic> request) {
    final List<dynamic> params = (request["params"] as List<dynamic>?) ?? const [];
    switch (request["method"]) {
      case "server.version":
        return ["FakeElectrum 1.0", "1.4"];
      case "blockchain.headers.subscribe":
        return {"height": 800000, "hex": ""};
      case "blockchain.scripthash.get_history":
        final String scriptHash = params.first as String;
        return _usedScriptHashes.contains(scriptHash)
            ? [
                {"tx_hash": scriptHash, "height": 799000},
              ]
            : [];
      case "blockchain.scripthash.listunspent":
      case "blockchain.scripthash.get_mempool":
        return [];
      case "blockchain.scripthash.get_balance":
        return {"confirmed": 0, "unconfirmed": 0};
      default:
        return null;
    }
  }

  Future<void> close() => _server.close();
}

/// A wallet restored from [_mnemonic], connected to [node].
Future<ElectrumWallet> _restore(String name, _FakeNode node) async {
  final WalletInfo walletInfo = WalletInfo.external(
    id: name,
    name: name,
    type: WalletType.bitcoin,
    isRecovery: true,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: "",
  );
  final ElectrumWallet wallet = ElectrumWallet(
    password: "",
    walletInfo: walletInfo,
    derivationInfo: DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/0'",
    ),
    unspentCoinsInfo: _NoUnspentsBox(),
    network: BitcoinNetwork.mainnet,
    encryptionFileUtils: encryptionFileUtilsFor(false),
    seedBytes: _seed,
    mnemonic: _mnemonic,
    currency: CryptoCurrency.btc,
  );
  wallet.walletAddresses = _Addresses(walletInfo, wallet);
  await wallet.walletAddresses.init();

  await wallet.connectToNode(
    node: Node(uri: "127.0.0.1:${node._server.port}", type: WalletType.bitcoin, useSSL: false),
  );
  final DateTime end = DateTime.now().add(const Duration(seconds: 10));
  while (!wallet.electrumClient.isConnected && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(wallet.electrumClient.isConnected, isTrue);
  return wallet;
}

/// The address discovery part of ElectrumWalletBase.startSync.
Future<void> _sync(ElectrumWallet wallet) async {
  await wallet.subscribeForUpdates();
  await wallet.checkIfBatchSupported();
  await wallet.updateTransactions();
}

int _indexOf(ElectrumWallet wallet, String address) =>
    wallet.walletAddresses.allAddresses.firstWhere((record) => record.address == address).index;

/// What the Receive page's rotate button does (WalletAddressListViewModel.rotateAddress).
Future<int> _tapNewAddress(ElectrumWallet wallet) async {
  final BaseBitcoinAddressRecord record = wallet.walletAddresses.generateNewAddress();
  await Future<void>.delayed(Duration.zero);
  wallet.walletAddresses.address = record.address;
  return _indexOf(wallet, wallet.walletAddresses.address);
}

class _Outcome {
  _Outcome({required this.onScreen, required this.handedOut, required this.farthestFound});

  /// The receive index on screen when the Receive page opens.
  final int onScreen;

  /// The receive indexes "new address" handed out.
  final List<int> handedOut;

  /// Whether restoring the seed again found a payment to the farthest address handed out.
  final bool farthestFound;
}

/// Restores a seed whose receive addresses at [usedIndexes] have history, syncs [syncs] times,
/// opens the Receive page and taps "new address" [taps] times. Then the farthest address handed
/// out gets paid and the seed is restored again, synced as on three app starts.
Future<_Outcome> _restoreTapPayRestore({
  required Set<int> usedIndexes,
  required int syncs,
  required int taps,
  required bool batch,
}) async {
  final _FakeNode node = await _FakeNode.start(usedIndexes, batch: batch);
  final ElectrumWallet wallet = await _restore("restored", node);
  for (var i = 0; i < syncs; i++) {
    await _sync(wallet);
  }
  wallet.walletAddresses.address = wallet.walletAddresses.latestAddress;
  final int onScreen = _indexOf(wallet, wallet.walletAddresses.address);
  final List<int> handedOut = [for (var i = 0; i < taps; i++) await _tapNewAddress(wallet)];
  await wallet.close();
  await node.close();

  final int farthest = handedOut.reduce(max);
  final _FakeNode paidNode = await _FakeNode.start({...usedIndexes, farthest}, batch: batch);
  final ElectrumWallet restoredAgain = await _restore("restored again", paidNode);
  for (var i = 0; i < 3; i++) {
    await _sync(restoredAgain);
  }
  final bool farthestFound = restoredAgain.walletAddresses.allAddresses
      .any((record) => record.address == _receive(farthest) && record.isUsed);
  await restoredAgain.close();
  await paidNode.close();

  return _Outcome(onScreen: onScreen, handedOut: handedOut, farthestFound: farthestFound);
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db!.execute(
      "CREATE TABLE IF NOT EXISTS walletInfoAddress "
      "(walletInfoAddressId INTEGER PRIMARY KEY, walletInfoId INTEGER, type INTEGER, "
      "address TEXT)",
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CakeTor.instance = CakeTorDisabled();
  });

  test("the test wallet derives BIP84 addresses (test vector m/84'/0'/0'/0/0)", () {
    expect(_receive(0), "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu");
  });

  for (final batch in [true, false]) {
    final String server = batch ? "server with batches" : "server without batches";

    for (final (String wallet, Set<int> usedIndexes, int syncs, int onScreen) in [
      ("nothing received", <int>{}, 1, 0),
      ("receive/0 used", {0}, 2, 1),
      ("receive/0 and receive/22 used", {0, 22}, 1, 1),
      ("receive/0 and receive/20 used, synced twice", {0, 20}, 2, 1),
    ]) {
      test(
        "$server, $wallet: new address hands out the next two, and a restore finds a payment "
        "to the second",
        () async {
          final _Outcome outcome = await _restoreTapPayRestore(
            usedIndexes: usedIndexes,
            syncs: syncs,
            taps: 2,
            batch: batch,
          );

          expect(outcome.onScreen, onScreen);
          expect(outcome.handedOut, [onScreen + 1, onScreen + 2]);
          expect(outcome.farthestFound, isTrue);
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    }
  }

  test(
    "40 taps hand out receive/2 to 42 in order, each once, and a restore finds a payment to "
    "receive/42, the last address within 20 of receive/22",
    () async {
      final _Outcome outcome = await _restoreTapPayRestore(
        usedIndexes: {0, 22},
        syncs: 1,
        taps: 40,
        batch: true,
      );

      expect(outcome.handedOut, [
        for (var i = 2; i <= 22 + ElectrumWalletAddressesBase.gap; i++)
          if (i != 22) i,
      ]);
      expect(outcome.farthestFound, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
