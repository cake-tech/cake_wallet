// The derivation recovery flow: which chains it searches, how it finds keys and used addresses,
// and a full scan + sweep on a real LitecoinWallet against a fake chain.
import "dart:io";
import "dart:typed_data";

import "package:bip39/bip39.dart" as bip39;
import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_mnemonic.dart" as electrum_mnemonic;
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_bitcoin/derivation_recovery/derivation_recovery_service.dart";
import "package:cw_bitcoin/derivation_recovery/recovery_derivations.dart";
import "package:cw_bitcoin/derivation_recovery/recovery_scanner.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/litecoin_wallet.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/cake_hive.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/mweb_utxo.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// Public BIP39 test vector; any valid mnemonic works.
const _mnemonic =
    "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
const _ltc = LitecoinNetwork.mainnet;
const _btc = BitcoinNetwork.mainnet;

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

/// A chain where the given addresses have history, and the given unspent outputs.
class _FakeChain implements RecoveryChainSource {
  _FakeChain(BasedUtxoNetwork network, Map<String, List<RecoveryUnspent>> unspentsByAddress)
      : _unspents = {
          for (final entry in unspentsByAddress.entries)
            BitcoinAddressUtils.scriptHash(entry.key, network: network): entry.value,
        };

  final Map<String, List<RecoveryUnspent>> _unspents;

  @override
  Future<Set<String>> usedScriptHashes(List<String> scriptHashes) async =>
      scriptHashes.where(_unspents.containsKey).toSet();

  @override
  Future<Map<String, List<RecoveryUnspent>>> unspents(List<String> scriptHashes) async =>
      {for (final scriptHash in scriptHashes) scriptHash: _unspents[scriptHash] ?? const []};
}

RecoveryUnspent _unspent(String hash, int value) =>
    RecoveryUnspent(hash: hash * 64, vout: 0, value: value, height: 100);

String _txHash(String digit) => digit * 64;

Bip32Slip10Secp256k1 _hd(List<int> seed, String path) =>
    Bip32Slip10Secp256k1.fromSeed(seed).derivePath(path) as Bip32Slip10Secp256k1;

BitcoinAddressRecord _record(Bip32Slip10Secp256k1 hd, int index, {required bool isHidden}) =>
    BitcoinAddressRecord(
      generateP2WPKHAddress(hd: hd, index: index, network: _ltc),
      index: index,
      isHidden: isHidden,
      isHiddenChecked: true,
      type: SegwitAddresType.p2wpkh,
      network: _ltc,
    );

var _walletCount = 0;

Future<LitecoinWallet> _initLitecoinWallet(
  List<int> seed, {
  List<BitcoinAddressRecord>? initialAddresses,
}) async {
  final name = "derivation_recovery_test_${_walletCount++}";
  final wallet = LitecoinWallet(
    password: "password",
    walletInfo: WalletInfo.external(
      id: name,
      name: name,
      type: WalletType.litecoin,
      isRecovery: true,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "",
    ),
    derivationInfo:
        DerivationInfo(derivationType: DerivationType.bip39, derivationPath: "m/84'/2'/0'"),
    unspentCoinsInfo: await CakeHive.openBox<UnspentCoinsInfo>("${name}_unspent"),
    encryptionFileUtils: encryptionFileUtilsFor(false),
    seedBytes: Uint8List.fromList(seed),
    mnemonic: _mnemonic,
    passphrase: "",
    initialAddresses: initialAddresses,
  );
  await wallet.init();
  return wallet;
}

void main() {
  late Directory tempDir;
  late List<int> bip39Seed;
  late List<int> electrumSeed;
  late RecoveryMasters masters;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    tempDir = Directory.systemTemp.createTempSync("derivation_recovery_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    CakeHive.init(tempDir.path);
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }
    if (!CakeHive.isAdapterRegistered(MwebUtxo.typeId)) {
      CakeHive.registerAdapter(MwebUtxoAdapter());
    }

    sqfliteFfiInit();
    // WalletAddresses' constructor loads the wallet's used/hidden/manual addresses.
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db!.execute(
      "CREATE TABLE walletInfoAddress "
      "(walletInfoAddressId INTEGER PRIMARY KEY, walletInfoId INTEGER, type INTEGER, "
      "address TEXT)",
    );

    bip39Seed = bip39.mnemonicToSeed(_mnemonic);
    electrumSeed = await electrum_mnemonic.mnemonicToSeedBytes(_mnemonic);
    masters = RecoveryMasters.fromSeeds(bip39Seed: bip39Seed, electrumSeed: electrumSeed);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group("recovery chains", () {
    test("Litecoin: master root, Electrum and BIP44-86 on coin types 2 and 0, both seeds", () {
      final chains = recoveryChains(nativeCoinType: 2, supportsTaproot: false);
      final paths = chains.map((chain) => "$chain").toSet();

      for (final seed in ["bip39", "electrum"]) {
        expect(
          paths,
          containsAll([
            "$seed m/0",
            "$seed m/1",
            "$seed m/0'/0",
            "$seed m/0'/1",
            for (final coinType in [2, 0])
              for (final purpose in [44, 49, 84, 86])
                for (final chain in [0, 1]) "$seed m/$purpose'/$coinType'/0'/$chain",
          ]),
        );
      }
      expect(chains, hasLength(2 * (2 + 2 + 2 * 8)));

      final root = chains.firstWhere((chain) => chain.path == "m/0");
      expect(root.addressTypes, [SegwitAddresType.p2wpkh, P2pkhAddressType.p2pkh]);
      expect(chains.expand((chain) => chain.addressTypes), isNot(contains(SegwitAddresType.p2tr)));
    });

    test("Bitcoin: coin type 0 once, Taproot on m/86'", () {
      final chains = recoveryChains(nativeCoinType: 0, supportsTaproot: true);

      expect(chains, hasLength(2 * (2 + 2 + 8)));
      expect(
        chains.firstWhere((chain) => chain.path == "m/86'/0'/0'/0").addressTypes,
        [SegwitAddresType.p2tr, SegwitAddresType.p2wpkh],
      );
    });
  });

  group("key search", () {
    Future<RecoveryKey> find(
      String address,
      BitcoinAddressType type,
      BasedUtxoNetwork network, {
      required int nativeCoinType,
    }) async {
      final key = await searchRecoveryKey(
        masters: masters,
        chains: recoveryChains(nativeCoinType: nativeCoinType, supportsTaproot: false),
        address: address,
        type: type,
        network: network,
      );
      expect(key, isNotNull);
      expect(addressForPublicKey(key!.privateKey.getPublic(), type, network), address);
      return key;
    }

    test("master-root m/0/17, P2WPKH, BIP39 seed (the 2026-09-04 Bitcoin case)", () async {
      final address = generateP2WPKHAddress(hd: _hd(bip39Seed, "m/0"), index: 17, network: _btc);

      final key = await find(address, SegwitAddresType.p2wpkh, _btc, nativeCoinType: 0);
      expect("${key.chain}", "bip39 m/0");
      expect(key.index, 17);
    });

    test("Electrum 2 standard wallet: m/1/5, P2PKH, Electrum seed", () async {
      final address = generateP2PKHAddress(hd: _hd(electrumSeed, "m/1"), index: 5, network: _btc);

      final key = await find(address, P2pkhAddressType.p2pkh, _btc, nativeCoinType: 0);
      expect("${key.chain}", "electrum m/1");
      expect(key.index, 5);
    });

    test("Litecoin on Bitcoin's coin type: m/84'/0'/0'/0/317 (the 2026-08-05 case)", () async {
      final address =
          generateP2WPKHAddress(hd: _hd(bip39Seed, "m/84'/0'/0'/0"), index: 317, network: _ltc);

      final key = await find(address, SegwitAddresType.p2wpkh, _ltc, nativeCoinType: 2);
      expect("${key.chain}", "bip39 m/84'/0'/0'/0");
      expect(key.index, 317);
    });
  });

  test("scanner keeps going 20 past the last used address, then stops", () async {
    final chain = _hd(bip39Seed, "m/84'/2'/0'/0");
    final usedAt = [195, 214];
    final source = _FakeChain(_ltc, {
      for (final index in usedAt)
        generateP2WPKHAddress(hd: chain, index: index, network: _ltc): const [],
    });

    var checked = 0;
    final used = await RecoveryScanner(
      masters: masters,
      chains: recoveryChains(nativeCoinType: 2, supportsTaproot: false),
      network: _ltc,
      source: source,
      onProgress: (count) => checked = count,
    ).usedAddresses();

    expect(used.map((address) => address.index), usedAt);
    // 30 chain/type pairs per seed × 200, then 200..215 and 216..234 on the used chain.
    expect(checked, 2 * 30 * 200 + 16 + 19);
  });

  test("sweeps coins on other paths and wrongly keyed wallet coins, not the wallet's own",
      () async {
    final ownReceive = _hd(bip39Seed, "m/84'/2'/0'/0");
    final ownChange = _hd(bip39Seed, "m/84'/2'/0'/1");
    // A wallet record on Bitcoin's coin type at index 317, labelled as the wallet's own standard
    // address: the wallet signs it with the m/84'/2'/0' key, which doesn't match.
    final misKeyed = _record(_hd(bip39Seed, "m/84'/0'/0'/0"), 317, isHidden: false);
    final wallet = await _initLitecoinWallet(
      bip39Seed,
      initialAddresses: [
        for (var i = 0; i < ElectrumWalletAddressesBase.defaultReceiveAddressesCount; i++)
          _record(ownReceive, i, isHidden: false),
        for (var i = 0; i < ElectrumWalletAddressesBase.defaultChangeAddressesCount; i++)
          _record(ownChange, i, isHidden: true),
        misKeyed,
      ],
    );
    final ownRecord = wallet.walletAddresses.allAddresses.firstWhere((a) => a.index == 0);
    wallet.unspentCoins
      ..clear()
      ..addAll([
        BitcoinUnspent(ownRecord, _txHash("1"), 50000, 0),
        BitcoinUnspent(misKeyed, _txHash("2"), 70000, 0),
      ]);

    final foreign =
        generateP2WPKHAddress(hd: _hd(electrumSeed, "m/84'/2'/0'/0"), index: 150, network: _ltc);
    final root = generateP2WPKHAddress(hd: _hd(bip39Seed, "m/0"), index: 17, network: _ltc);
    final source = _FakeChain(_ltc, {
      foreign: [_unspent("3", 100000)],
      root: [_unspent("4", 30000)],
      ownRecord.address: [_unspent("1", 50000)],
    });

    final addressesBefore = wallet.walletAddresses.allAddresses.length;
    final walletFileBefore = wallet.toJSON();

    final service = DerivationRecoveryService(wallet, source: source);
    final result = await service.scan();

    expect(
      {for (final coin in result.coins) coin.address: coin.value},
      {foreign: 100000, root: 30000, misKeyed.address: 70000},
    );
    expect(result.coins.firstWhere((c) => c.address == misKeyed.address).isWalletCoin, isTrue);
    expect(result.unrecoverableCoins, isEmpty);
    expect(result.total, 200000);

    // The wallet itself is untouched.
    expect(wallet.walletAddresses.allAddresses, hasLength(addressesBefore));
    expect(wallet.toJSON(), walletFileBefore);

    final pending = await service.createSweepTransaction(result, feeRate: 2);
    expect(pending.amount.amount + pending.fee.amount, BigInt.from(200000));

    final transaction = BtcTransaction.fromRaw(pending.hex);
    expect(transaction.outputs, hasLength(1));
    final destination = transaction.outputs.single.scriptPubKey.toAddress(network: _ltc);
    expect(wallet.walletAddresses.allAddresses.map((a) => a.address), contains(destination));

    // Every input is signed with the key of the address it spends.
    final addressByTxHash = {for (final coin in result.coins) coin.hash: coin.address};
    expect(transaction.inputs, hasLength(3));
    for (var i = 0; i < transaction.inputs.length; i++) {
      final publicKey = ECPublic.fromHex(transaction.witnesses[i].stack.last);
      expect(
        publicKey.toP2wpkhAddress().toAddress(_ltc),
        addressByTxHash[transaction.inputs[i].txId],
      );
    }
  });

  test("a wallet coin whose key the search can't find is reported, not swept", () async {
    final ownReceive = _hd(bip39Seed, "m/84'/2'/0'/0");
    final misKeyed = _record(_hd(bip39Seed, "m/84'/0'/0'/0"), 10, isHidden: false);
    final wallet = await _initLitecoinWallet(
      bip39Seed,
      initialAddresses: [
        for (var i = 0; i < ElectrumWalletAddressesBase.defaultReceiveAddressesCount; i++)
          _record(ownReceive, i, isHidden: false),
        misKeyed,
      ],
    );
    wallet.unspentCoins
      ..clear()
      ..add(BitcoinUnspent(misKeyed, _txHash("5"), 40000, 0));

    // Neither the scan (depth 5) nor the key search (depth 5) reaches index 10.
    final result = await DerivationRecoveryService(
      wallet,
      source: _FakeChain(_ltc, {}),
      depth: 5,
      keySearchDepth: 5,
    ).scan();

    expect(result.coins, isEmpty);
    expect(result.unrecoverableCoins.single.address, misKeyed.address);
    expect(result.unrecoverableTotal, 40000);
  });

  test("only Bitcoin and Litecoin seed wallets are supported", () async {
    final wallet = await _initLitecoinWallet(bip39Seed);
    expect(DerivationRecoveryService.isSupported(wallet), isTrue);
  });
}
