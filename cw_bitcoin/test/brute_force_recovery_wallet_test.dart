// Runs a real LitecoinWallet through init() to check how the brute-force recovery sits on top of
// the wallet's own address bookkeeping: recovery addresses are scanned and spendable, but they
// never reach the wallet's own branches, receive/change handout, new indexes or wallet file.
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:bip39/bip39.dart" as bip39;
import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_mnemonic.dart" as electrum_mnemonic;
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_bitcoin/bitcoin_wallet.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/litecoin_wallet.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/cake_hive.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/mweb_utxo.dart";
import "package:cw_core/payjoin_session.dart";
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
const _network = LitecoinNetwork.mainnet;

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

Bip32Slip10Secp256k1 _hd(List<int> seed, String path) =>
    Bip32Slip10Secp256k1.fromSeed(seed).derivePath(path) as Bip32Slip10Secp256k1;

String _addr(Bip32Slip10Secp256k1 hd, int index) =>
    generateP2WPKHAddress(hd: hd, index: index, network: _network);

BitcoinAddressRecord _record(
  Bip32Slip10Secp256k1 hd,
  int index, {
  required bool isHidden,
  bool isHiddenChecked = true,
}) =>
    BitcoinAddressRecord(
      _addr(hd, index),
      index: index,
      isHidden: isHidden,
      isHiddenChecked: isHiddenChecked,
      type: SegwitAddresType.p2wpkh,
      network: _network,
    );

// The receive/change window init() keeps for a Litecoin wallet's own P2WPKH branch.
List<BitcoinAddressRecord> _ownWindow(List<int> seed, String accountPath) => [
      for (var i = 0; i < ElectrumWalletAddressesBase.defaultReceiveAddressesCount; i++)
        _record(_hd(seed, "$accountPath/0"), i, isHidden: false),
      for (var i = 0; i < ElectrumWalletAddressesBase.defaultChangeAddressesCount; i++)
        _record(_hd(seed, "$accountPath/1"), i, isHidden: true),
    ];

var _walletCount = 0;

Future<LitecoinWallet> _initLitecoinWallet({
  required List<int> seed,
  required String derivationPath,
  List<BitcoinAddressRecord>? initialAddresses,
}) async {
  final name = "recovery_test_${_walletCount++}";
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
    derivationInfo: DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: derivationPath,
    ),
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

// A BIP39 Bitcoin wallet, which has the multi-account support (accounts table in SQLite).
Future<BitcoinWallet> _initBitcoinWallet({required List<int> seed}) async {
  final name = "recovery_test_${_walletCount++}";
  final wallet = BitcoinWallet(
    password: "password",
    walletInfo: WalletInfo.external(
      id: name,
      name: name,
      type: WalletType.bitcoin,
      isRecovery: true,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "",
    ),
    derivationInfo: DerivationInfo(
      derivationType: DerivationType.bip39,
      derivationPath: "m/84'/0'/0'",
    ),
    unspentCoinsInfo: await CakeHive.openBox<UnspentCoinsInfo>("${name}_unspent"),
    payjoinBox: await CakeHive.openBox<PayjoinSession>("${name}_payjoin"),
    encryptionFileUtils: encryptionFileUtilsFor(false),
    seedBytes: Uint8List.fromList(seed),
    mnemonic: _mnemonic,
    passphrase: "",
    useLightning: false,
  );
  await wallet.init();
  return wallet;
}

// The private key estimateSendAllTx (→ _createUTXOS) picks to spend a UTXO on [record].
Future<ECPrivate> _spendingKeyFor(ElectrumWallet wallet, BitcoinAddressRecord record) async {
  wallet.unspentCoins
    ..clear()
    ..add(BitcoinUnspent(record, "00" * 32, 100000, 0));

  final destination = wallet.walletAddresses.ownAddresses.first.address;
  final estimate = await wallet.estimateSendAllTx(
    [
      BitcoinOutput(
        address: RegexUtils.addressTypeFromStr(destination, wallet.network),
        value: BigInt.zero,
      ),
    ],
    1,
  );
  return estimate.inputPrivKeyInfos.single.privkey;
}

void main() {
  late Directory tempDir;
  late List<int> bip39Seed;
  late List<int> electrumSeed;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    tempDir = Directory.systemTemp.createTempSync("brute_force_recovery_wallet_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    CakeHive.init(tempDir.path);
    if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
      CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
    }
    if (!CakeHive.isAdapterRegistered(MwebUtxo.typeId)) {
      CakeHive.registerAdapter(MwebUtxoAdapter());
    }
    if (!CakeHive.isAdapterRegistered(PayjoinSession.typeId)) {
      CakeHive.registerAdapter(PayjoinSessionAdapter());
    }

    sqfliteFfiInit();
    // WalletAddresses' constructor loads the wallet's used/hidden/manual addresses.
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db!.execute(
      "CREATE TABLE walletInfoAddress "
      "(walletInfoAddressId INTEGER PRIMARY KEY, walletInfoId INTEGER, type INTEGER, "
      "address TEXT)",
    );
    // Bitcoin's account list (BIP39 wallets support multiple accounts).
    await db!.execute(
      "CREATE TABLE walletInfoAccount "
      "(walletInfoAccountId INTEGER PRIMARY KEY, walletInfoId INTEGER, accountIndex INTEGER, "
      "label TEXT)",
    );

    bip39Seed = bip39.mnemonicToSeed(_mnemonic);
    electrumSeed = await electrum_mnemonic.mnemonicToSeedBytes(_mnemonic);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test("recovery addresses are scanned but stay out of the wallet's own bookkeeping", () async {
    final wallet = await _initLitecoinWallet(seed: bip39Seed, derivationPath: "m/84'/2'/0'");
    final addresses = wallet.walletAddresses;

    // 2 seeds × (m/0' + 4 purposes × coin types {2, 0}) × 2 chains × 200, minus the 22 + 17
    // the wallet already has on its own m/84'/2'/0' branch.
    const ownCount = 22 + 17;
    expect(addresses.ownAddresses, hasLength(ownCount));
    expect(addresses.recoveryAddresses, hasLength(2 * 18 * 200 - ownCount));
    expect(addresses.allAddresses, hasLength(2 * 18 * 200));

    // A cross-seed address (Electrum seed, BIP84 Litecoin path) is scanned.
    final crossSeed = _addr(_hd(electrumSeed, "m/84'/2'/0'/0"), 150);
    expect(addresses.allAddresses.map((a) => a.address), contains(crossSeed));
    expect(addresses.ownAddresses.map((a) => a.address), isNot(contains(crossSeed)));

    // The wallet's own gap scan only sees its own branch.
    final receiveBranch = wallet.getAddressBranchByType(
      type: SegwitAddresType.p2wpkh,
      hidden: false,
      legacy: false,
      accountIndex: 0,
    );
    expect(receiveBranch.map((a) => a.index), List.generate(22, (i) => i));

    // The wallet file keeps only its own addresses; recovery ones are re-derived on open.
    final saved = (jsonDecode(wallet.toJSON()) as Map<String, dynamic>)["addresses"] as List;
    expect(saved, hasLength(ownCount));

    // Litecoin's saved addresses still include its MWEB records, as they did before.
    final mweb = BitcoinAddressRecord(
      "ltcmweb1recoverytest",
      index: 0,
      type: SegwitAddresType.mweb,
      network: _network,
    );
    addresses.addMwebAddresses([mweb]);
    final savedWithMweb =
        (jsonDecode(wallet.toJSON()) as Map<String, dynamic>)["addresses"] as List;
    expect(savedWithMweb, hasLength(ownCount + 1));
    expect(
      savedWithMweb.map((json) => (jsonDecode(json as String) as Map)["address"]),
      contains(mweb.address),
    );

    // With every own address used, the next receive and change addresses continue the wallet's
    // own branch at the next index instead of handing out a recovery address.
    for (final record in addresses.ownAddresses) {
      record.setAsUsed();
    }
    addresses.updateReceiveAddresses();
    addresses.updateChangeAddresses();

    final ownReceive = _hd(bip39Seed, "m/84'/2'/0'/0");
    final ownChange = _hd(bip39Seed, "m/84'/2'/0'/1");
    expect(addresses.generateNewAddress().address, _addr(ownReceive, 22));
    expect((await addresses.getChangeAddress()).address, _addr(ownChange, 17));
  });

  test("a UTXO on a recovery address is spent with that address's key", () async {
    final wallet = await _initLitecoinWallet(seed: bip39Seed, derivationPath: "m/84'/2'/0'");

    final crossSeed = _addr(_hd(electrumSeed, "m/84'/2'/0'/0"), 150);
    final record =
        wallet.walletAddresses.recoveryAddresses.firstWhere((a) => a.address == crossSeed);

    final key = await _spendingKeyFor(wallet, record);
    expect(key.getPublic().toP2wpkhAddress().toAddress(_network), crossSeed);
  });

  test("brute force still recovers a key beyond the recovery window (m/84'/0'/0'/0/317)", () async {
    // The real case: a Litecoin wallet's address on Bitcoin's coin type at index 317, saved as
    // one of the wallet's own records. 317 is past the 200-address recovery window, so only the
    // signing-time search finds its key.
    final foreign = _record(_hd(bip39Seed, "m/84'/0'/0'/0"), 317, isHidden: false);
    final wallet = await _initLitecoinWallet(
      seed: bip39Seed,
      derivationPath: "m/84'/2'/0'",
      initialAddresses: [..._ownWindow(bip39Seed, "m/84'/2'/0'"), foreign],
    );
    expect(wallet.walletAddresses.ownAddresses, contains(foreign));

    final key = await _spendingKeyFor(wallet, foreign);
    expect(key.getPublic().toP2wpkhAddress().toAddress(_network), foreign.address);
  });

  test("records an earlier recovery build saved as own addresses move to the recovery list",
      () async {
    // Wallet saved with Bitcoin's m/84'/0'/0' as its derivation path, so that path is its legacy
    // branch. Pre-#2825 records from it carry the standard label (P2WPKH defaults to standard).
    final legacyReceive = _hd(bip39Seed, "m/84'/0'/0'/0");
    final legacyChange = _hd(bip39Seed, "m/84'/0'/0'/1");
    final mislabeledLegacy = [
      for (var i = 0; i < 22; i++) _record(legacyReceive, i, isHidden: false),
    ];
    // Before isHiddenChecked, every open flipped the change label of such records, so about half
    // of these wallets have them on the other chain's label.
    final flippedLegacy = [
      for (var i = 30; i < 40; i++) _record(legacyReceive, i, isHidden: true),
      for (var i = 0; i < 10; i++) _record(legacyChange, i, isHidden: false),
    ];
    // What the previous build of this recovery persisted: alt-seed m/0' records as own records.
    final artifacts = [
      for (var i = 0; i < 200; i++)
        _record(_hd(electrumSeed, "m/0'/0"), i, isHidden: false, isHiddenChecked: false),
      for (var i = 0; i < 200; i++)
        _record(_hd(electrumSeed, "m/0'/1"), i, isHidden: true, isHiddenChecked: false),
    ];

    final wallet = await _initLitecoinWallet(
      seed: bip39Seed,
      derivationPath: "m/84'/0'/0'",
      initialAddresses: [
        ..._ownWindow(bip39Seed, "m/84'/2'/0'"),
        ...mislabeledLegacy,
        ...flippedLegacy,
        ...artifacts,
      ],
    );
    final addresses = wallet.walletAddresses;
    final own = addresses.ownAddresses.map((a) => a.address).toSet();
    final recovery = addresses.recoveryAddresses.map((a) => a.address).toSet();

    const ownCount = 22 + 17 + 22 + 20;
    expect(own, hasLength(ownCount));
    expect(own, containsAll(flippedLegacy.map((a) => a.address)));
    expect(own.intersection(artifacts.map((a) => a.address).toSet()), isEmpty);
    expect(recovery, containsAll(artifacts.map((a) => a.address)));
    expect(recovery.intersection(own), isEmpty);
    expect(addresses.allAddresses, hasLength(own.length + recovery.length));

    final saved = (jsonDecode(wallet.toJSON()) as Map<String, dynamic>)["addresses"] as List;
    expect(saved, hasLength(ownCount));

    // The legacy records stay the wallet's own and spend with the key of the chain they're really
    // on, whatever their label says.
    for (final record in [mislabeledLegacy[5], flippedLegacy[0], flippedLegacy[15]]) {
      final key = await _spendingKeyFor(wallet, record);
      expect(key.getPublic().toP2wpkhAddress().toAddress(_network), record.address);
    }
  });

  test("Bitcoin with accounts support: recovery stays on account 0 and out of the own sets",
      () async {
    final wallet = await _initBitcoinWallet(seed: bip39Seed);
    final addresses = wallet.walletAddresses;
    const btc = BitcoinNetwork.mainnet;

    expect(wallet.hasAccountsSupport, isTrue);
    expect(addresses.accountIndexes, [0]);

    // Account 0 keeps its 5 standard + 3 legacy address sets of 22 + 17.
    expect(addresses.ownAddresses, hasLength(8 * (22 + 17)));
    // 2 seeds × (m/0' + 4 purposes × coin type 0) × 2 chains × 200, minus the own m/84'/0'/0'
    // P2WPKH window.
    expect(addresses.recoveryAddresses, hasLength(2 * 10 * 200 - (22 + 17)));
    expect(addresses.recoveryAddresses.every((a) => a.accountIndex == 0), isTrue);

    final ownReceive = _hd(bip39Seed, "m/84'/0'/0'/0");
    expect(addresses.addressForBuy, generateP2WPKHAddress(hd: ownReceive, index: 0, network: btc));

    // A UTXO on the Electrum seed's m/0'/0/5 spends with that address's key.
    final crossSeed =
        generateP2WPKHAddress(hd: _hd(electrumSeed, "m/0'/0"), index: 5, network: btc);
    final record = addresses.recoveryAddresses.firstWhere((a) => a.address == crossSeed);
    final key = await _spendingKeyFor(wallet, record);
    expect(key.getPublic().toP2wpkhAddress().toAddress(btc), crossSeed);
  });
}
