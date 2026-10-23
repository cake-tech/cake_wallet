import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
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
import "package:cw_core/utils/tor/socks.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mobx/mobx.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final _master = Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));
final _receiveHd = _master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
final _changeHd = _master.derivePath("m/84'/0'/0'/1") as Bip32Slip10Secp256k1;
const _addressCount = 3;

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoUnspentsBox implements Box<UnspentCoinsInfo> {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Addresses extends BitcoinWalletAddresses {
  _Addresses(super.walletInfo)
      : super(
          mainHdByTypeAndAccount: {
            0: {SegwitAddresType.p2wpkh: _receiveHd},
          },
          sideHdByTypeAndAccount: {
            0: {SegwitAddresType.p2wpkh: _changeHd},
          },
          accountIndexes: [0],
          currentAccountIndex: 0,
          legacyMainHd: _receiveHd,
          legacySideHd: _changeHd,
          network: BitcoinNetwork.mainnet,
          isHardwareWallet: false,
          payjoinManager: _NoPayjoin(),
          masterHd: _master,
          initialAddresses: [
            for (var i = 0; i < _addressCount; i++)
              BitcoinAddressRecord(
                generateP2WPKHAddress(hd: _receiveHd, network: BitcoinNetwork.mainnet, index: i),
                index: i,
                type: SegwitAddresType.p2wpkh,
                network: BitcoinNetwork.mainnet,
              ),
          ],
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

/// Electrum server stand-in: answers every request with a null result and counts what it gets.
class _FakeNode {
  _FakeNode._(this._server);

  final ServerSocket _server;
  int subscribes = 0;

  static Future<_FakeNode> start({int port = 0}) async {
    final node = _FakeNode._(await ServerSocket.bind(InternetAddress.loopbackIPv4, port));
    node._server.listen((c) {
      c.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          final request = json.decode(line) as Map;
          if (request["method"] == "blockchain.scripthash.subscribe") {
            node.subscribes++;
          }
          c.write('{"jsonrpc":"2.0","result":null,"id":${json.encode(request['id'])}}\n');
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

/// Accepts connections and never answers, so a TLS handshake to it never finishes.
Future<ServerSocket> _silentServer(List<Socket> accepted) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((c) {
    accepted.add(c);
    c.listen((_) {}, onError: (_) {});
  });
  return server;
}

Future<int> _refusedPort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = s.port;
  await s.close();
  return port;
}

/// SOCKS5 stand-in for Tor that sends every CONNECT to 127.0.0.1:[targetPort].
Future<ServerSocket> _fakeTor(int targetPort, {required void Function() onConnect}) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((c) {
    var stage = 0;
    Socket? upstream;
    c.listen(
      (data) async {
        if (stage == 0) {
          stage = 1;
          c.add([0x05, 0x00]);
        } else if (stage == 1) {
          stage = 2;
          onConnect();
          c.add([0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
          upstream = await Socket.connect(InternetAddress.loopbackIPv4, targetPort);
          upstream!.listen(c.add, onDone: () => c.destroy(), onError: (_) {});
        } else {
          upstream?.add(data);
        }
      },
      onError: (_) {},
      onDone: () => upstream?.destroy(),
    );
  });
  return server;
}

Node _node(int port, {bool useSSL = false}) =>
    Node(uri: "127.0.0.1:$port", type: WalletType.bitcoin, useSSL: useSSL);

ElectrumWallet _wallet() {
  final walletInfo = WalletInfo.external(
    id: "connection_test",
    name: "connection_test",
    type: WalletType.bitcoin,
    isRecovery: false,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: "",
  );
  return ElectrumWallet(
    password: "",
    walletInfo: walletInfo,
    derivationInfo: DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/0'",
    ),
    unspentCoinsInfo: _NoUnspentsBox(),
    network: BitcoinNetwork.mainnet,
    encryptionFileUtils: encryptionFileUtilsFor(false),
    seedBytes: Uint8List.fromList(List<int>.generate(64, (i) => i)),
    currency: CryptoCurrency.btc,
  )..walletAddresses = _Addresses(walletInfo);
}

Future<void> _waitFor(bool Function() done, Duration max) async {
  final end = DateTime.now().add(max);
  while (!done() && DateTime.now().isBefore(end)) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

bool _connectedTo(ElectrumWallet wallet, int port) =>
    wallet.syncStatus is ConnectedSyncStatus &&
    wallet.electrumClient.isConnected &&
    wallet.electrumClient.uri?.port == port;

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

  test("a node that refuses the connection ends in Lost connection, not Connecting", () async {
    final wallet = _wallet();

    await wallet.connectToNode(node: _node(await _refusedPort()));

    expect(wallet.syncStatus, isA<LostConnectionSyncStatus>());
    await wallet.close();
  });

  test(
    "after a failed connect, the wallet retries and connects once the node is back",
    () async {
      final port = await _refusedPort();
      final wallet = _wallet();
      await wallet.connectToNode(node: _node(port));

      final node = await _FakeNode.start(port: port);
      await _waitFor(() => _connectedTo(wallet, port), const Duration(seconds: 15));

      expect(_connectedTo(wallet, port), isTrue);
      await wallet.close();
      await node.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    "selecting another node while a connect hangs connects to it right away",
    () async {
      final accepted = <Socket>[];
      final stalled = await _silentServer(accepted);
      final good = await _FakeNode.start();
      final wallet = _wallet();

      unawaited(wallet.connectToNode(node: _node(stalled.port, useSSL: true)));
      await _waitFor(() => accepted.isNotEmpty, const Duration(seconds: 3));
      expect(wallet.syncStatus, isA<ConnectingSyncStatus>());

      await wallet.connectToNode(node: _node(good.port));
      await _waitFor(() => _connectedTo(wallet, good.port), const Duration(seconds: 8));

      expect(_connectedTo(wallet, good.port), isTrue);
      await wallet.close();
      await good.close();
      await stalled.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    "selecting the same node again while connecting does not start a second connect",
    () async {
      final accepted = <Socket>[];
      final stalled = await _silentServer(accepted);
      final wallet = _wallet();
      final node = _node(stalled.port, useSSL: true);

      unawaited(wallet.connectToNode(node: node));
      await _waitFor(() => accepted.isNotEmpty, const Duration(seconds: 3));
      unawaited(wallet.connectToNode(node: node));
      await Future.delayed(const Duration(seconds: 1));

      expect(accepted, hasLength(1));
      await wallet.close();
      await stalled.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    "turning Tor on while connecting reconnects through Tor",
    () async {
      final accepted = <Socket>[];
      final silent = await _silentServer(accepted);
      final good = await _FakeNode.start();
      var torConnects = 0;
      final tor = await _fakeTor(good.port, onConnect: () => torConnects++);
      final wallet = _wallet();
      final node = _node(silent.port);

      // Plain TCP to a server that never answers: the wallet stays on Connecting.
      await wallet.connectToNode(node: node);
      expect(wallet.syncStatus, isA<ConnectingSyncStatus>());

      CakeTor.instance = CakeTorSocks(tor.port);
      await wallet.connectToNode(node: node);

      expect(torConnects, 1);
      await _waitFor(() => wallet.syncStatus is ConnectedSyncStatus, const Duration(seconds: 8));
      expect(wallet.syncStatus, isA<ConnectedSyncStatus>());
      await wallet.close();
      await tor.close();
      await good.close();
      await silent.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test("app resume with an unreachable node does not start a sync", () async {
    final wallet = _wallet();
    await wallet.connectToNode(node: _node(await _refusedPort()));
    final statuses = <SyncStatus>[];
    final dispose = reaction((_) => wallet.syncStatus, statuses.add);

    await wallet.checkSocketHealth();

    dispose();
    expect(statuses.whereType<SyncronizingSyncStatus>(), isEmpty);
    expect(wallet.syncStatus, isA<LostConnectionSyncStatus>());
    await wallet.close();
  });

  test(
    "switching between two working nodes subscribes the addresses on the new node",
    () async {
      final a = await _FakeNode.start();
      final b = await _FakeNode.start();
      final wallet = _wallet();

      await wallet.connectToNode(node: _node(a.port));
      await _waitFor(() => _connectedTo(wallet, a.port), const Duration(seconds: 8));
      await wallet.subscribeForUpdates(); // what startSync does once connected
      await Future.delayed(const Duration(milliseconds: 300));
      expect(a.subscribes, greaterThanOrEqualTo(_addressCount));

      await wallet.connectToNode(node: _node(b.port));
      await _waitFor(() => _connectedTo(wallet, b.port), const Duration(seconds: 8));
      await wallet.subscribeForUpdates();
      await Future.delayed(const Duration(milliseconds: 300));

      expect(b.subscribes, a.subscribes);
      await wallet.close();
      await a.close();
      await b.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
