import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final Bip32Slip10Secp256k1 _master =
    Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));

Bip32Slip10Secp256k1 _hd(String path) => _master.derivePath(path) as Bip32Slip10Secp256k1;

final Bip32Slip10Secp256k1 _p2wpkhReceiveHd = _hd("m/84'/0'/0'/0");
final Bip32Slip10Secp256k1 _p2wpkhChangeHd = _hd("m/84'/0'/0'/1");
final Bip32Slip10Secp256k1 _p2pkhReceiveHd = _hd("m/44'/0'/0'/0");
final Bip32Slip10Secp256k1 _p2pkhChangeHd = _hd("m/44'/0'/0'/1");
final Bip32Slip10Secp256k1 _legacyReceiveHd = _hd("m/0'/0");
final Bip32Slip10Secp256k1 _legacyChangeHd = _hd("m/0'/1");

BitcoinAddressRecord _record(
  int index, {
  BitcoinAddressType type = SegwitAddresType.p2wpkh,
  bool isHidden = false,
  bool isLegacyDerivation = false,
  bool isUsed = false,
  int accountIndex = 0,
}) {
  final Bip32Slip10Secp256k1 hd = _hd(
    "m/1'/${type == P2pkhAddressType.p2pkh ? 44 : 84}'/$accountIndex'"
    "/${isLegacyDerivation ? 1 : 0}'/${isHidden ? 1 : 0}",
  );
  final String address = type == P2pkhAddressType.p2pkh
      ? generateP2PKHAddress(hd: hd, index: index, network: BitcoinNetwork.mainnet)
      : generateP2WPKHAddress(hd: hd, index: index, network: BitcoinNetwork.mainnet);

  return BitcoinAddressRecord(
    address,
    index: index,
    type: type,
    isHidden: isHidden,
    isLegacyDerivation: isLegacyDerivation,
    isUsed: isUsed,
    accountIndex: accountIndex,
    network: BitcoinNetwork.mainnet,
  );
}

List<BitcoinAddressRecord> _range(
  int start,
  int end, {
  BitcoinAddressType type = SegwitAddresType.p2wpkh,
  bool isHidden = false,
  bool isLegacyDerivation = false,
  bool isUsed = false,
  int accountIndex = 0,
}) =>
    [
      for (int i = start; i < end; i++)
        _record(
          i,
          type: type,
          isHidden: isHidden,
          isLegacyDerivation: isLegacyDerivation,
          isUsed: isUsed,
          accountIndex: accountIndex,
        ),
    ];

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Addresses extends BitcoinWalletAddresses {
  _Addresses(
    super.walletInfo, {
    required List<BitcoinAddressRecord> records,
    required Bip32Slip10Secp256k1 legacyReceiveHd,
    required Bip32Slip10Secp256k1 legacyChangeHd,
  }) : super(
          mainHdByTypeAndAccount: {
            0: {
              SegwitAddresType.p2wpkh: _p2wpkhReceiveHd,
              P2pkhAddressType.p2pkh: _p2pkhReceiveHd,
            },
          },
          sideHdByTypeAndAccount: {
            0: {
              SegwitAddresType.p2wpkh: _p2wpkhChangeHd,
              P2pkhAddressType.p2pkh: _p2pkhChangeHd,
            },
          },
          accountIndexes: [0],
          currentAccountIndex: 0,
          legacyMainHd: legacyReceiveHd,
          legacySideHd: legacyChangeHd,
          network: BitcoinNetwork.mainnet,
          isHardwareWallet: false,
          payjoinManager: _NoPayjoin(),
          initialAddresses: records,
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

Future<_Addresses> _addresses(
  List<BitcoinAddressRecord> records, {
  BitcoinAddressType addressPageType = SegwitAddresType.p2wpkh,
  bool legacyIsSameChain = false,
}) async {
  final WalletInfo walletInfo = WalletInfo.external(
    id: "address_index_test",
    name: "address_index_test",
    type: WalletType.bitcoin,
    isRecovery: false,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: "",
  )..addressPageType = addressPageType.toString();

  final _Addresses addresses = _Addresses(
    walletInfo,
    records: records,
    legacyReceiveHd: legacyIsSameChain ? _p2wpkhReceiveHd : _legacyReceiveHd,
    legacyChangeHd: legacyIsSameChain ? _p2wpkhChangeHd : _legacyChangeHd,
  );
  await walletInfo.getManualAddresses();
  return addresses;
}

List<int> _indexes(Iterable<BaseBitcoinAddressRecord> records) =>
    records.map((record) => record.index).toList();

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

  group("nextIndexOf", () {
    test("is 0 for an empty branch", () {
      expect(nextIndexOf(<BitcoinAddressRecord>[]), 0);
    });

    test("is the length for a contiguous branch", () {
      expect(nextIndexOf(_range(0, 22)), 22);
    });

    test("continues after the highest index when lower indexes are missing", () {
      expect(nextIndexOf([..._range(0, 22), _record(44)]), 45);
    });

    test("is not pushed ahead by a duplicated index", () {
      expect(nextIndexOf([..._range(0, 3), _record(2, isLegacyDerivation: true)]), 3);
    });

    test("does not depend on the order of the records", () {
      expect(nextIndexOf([_record(7), _record(2), _record(5)]), 8);
    });
  });

  group("firstFreeIndex", () {
    test("is 0 when nothing is taken", () {
      expect(firstFreeIndex(<int>{}), 0);
    });

    test("is the next index for a contiguous set", () {
      expect(firstFreeIndex({0, 1, 2}), 3);
    });

    test("fills the lowest hole", () {
      expect(firstFreeIndex({0, 1, 2, 4, 44}), 3);
    });

    test("is 0 when index 0 is missing", () {
      expect(firstFreeIndex({1, 2, 3}), 0);
    });
  });

  group("generateNewAddress", () {
    test("ignores legacy records that derive different keys", () async {
      final _Addresses addresses = await _addresses(
        [
          ..._range(0, 22, type: P2pkhAddressType.p2pkh),
          ..._range(0, 22, type: P2pkhAddressType.p2pkh, isLegacyDerivation: true),
        ],
        addressPageType: P2pkhAddressType.p2pkh,
      );

      final BaseBitcoinAddressRecord address = addresses.generateNewAddress();

      expect(address.index, 22);
      expect(
        address.address,
        generateP2PKHAddress(hd: _p2pkhReceiveHd, index: 22, network: BitcoinNetwork.mainnet),
      );
    });

    test("counts legacy records that derive the same keys", () async {
      final _Addresses addresses = await _addresses(
        [
          ..._range(0, 3),
          ..._range(0, 5, isLegacyDerivation: true),
        ],
        legacyIsSameChain: true,
      );

      expect(addresses.generateNewAddress().index, 5);
    });

    test("fills a hole left on the branch", () async {
      final _Addresses addresses = await _addresses([..._range(0, 22), _record(44)]);

      expect(addresses.generateNewAddress().index, 22);
      await Future<void>.delayed(Duration.zero);
      expect(addresses.generateNewAddress().index, 23);
    });

    test("ignores change records and other address types", () async {
      final _Addresses addresses = await _addresses([
        ..._range(0, 2),
        ..._range(0, 10, isHidden: true),
        ..._range(0, 10, type: P2pkhAddressType.p2pkh),
      ]);

      expect(addresses.generateNewAddress().index, 2);
    });

    test("ignores records of other accounts", () async {
      final _Addresses addresses = await _addresses([
        ..._range(0, 2),
        ..._range(0, 10, accountIndex: 1),
      ]);

      expect(addresses.generateNewAddress().index, 2);
    });

    test("starts at 0 on an empty branch", () async {
      final _Addresses addresses = await _addresses(<BitcoinAddressRecord>[]);

      expect(addresses.generateNewAddress().index, 0);
    });
  });

  group("getChangeAddress", () {
    test("creates new change addresses from the lowest free index", () async {
      final _Addresses addresses = await _addresses([
        ..._range(0, 30),
        ..._range(0, 3, isHidden: true, isUsed: true),
        _record(5, isHidden: true, isUsed: true),
      ]);

      final BitcoinAddressRecord address = await addresses.getChangeAddress();

      expect(address.index, 3);
      expect(address.isHidden, isTrue);
      expect(
        address.address,
        generateP2WPKHAddress(hd: _p2wpkhChangeHd, index: 3, network: BitcoinNetwork.mainnet),
      );
    });
  });

  group("discoverAddressesBatch", () {
    test("starts at 0 on an empty branch", () async {
      final _Addresses addresses = await _addresses(<BitcoinAddressRecord>[]);

      final List<BitcoinAddressRecord> discovered = await addresses.discoverAddressesBatch(
        <BitcoinAddressRecord>[],
        false,
        (_) async => <String>{},
        isLegacyDerivation: false,
      );

      expect(_indexes(discovered), List<int>.generate(20, (i) => i));
    });

    test("continues at the length of a contiguous branch", () async {
      final List<BitcoinAddressRecord> branch = _range(0, 22);
      final _Addresses addresses = await _addresses(branch);

      final List<BitcoinAddressRecord> discovered = await addresses.discoverAddressesBatch(
        branch,
        false,
        (_) async => <String>{},
        isLegacyDerivation: false,
      );

      expect(_indexes(discovered), List<int>.generate(20, (i) => 22 + i));
    });

    test("continues after the highest index of a branch with a hole", () async {
      final List<BitcoinAddressRecord> branch = [..._range(0, 22), _record(44)];
      final _Addresses addresses = await _addresses(branch);

      final List<BitcoinAddressRecord> discovered = await addresses.discoverAddressesBatch(
        branch,
        false,
        (_) async => <String>{},
        isLegacyDerivation: false,
      );

      expect(_indexes(discovered), List<int>.generate(20, (i) => 45 + i));
    });

    test("keeps going from the highest index while the gap has a used address", () async {
      final List<BitcoinAddressRecord> branch = [..._range(0, 22), _record(44)];
      final _Addresses addresses = await _addresses(branch);
      final String usedAddress =
          generateP2WPKHAddress(hd: _p2wpkhReceiveHd, index: 50, network: BitcoinNetwork.mainnet);

      final List<BitcoinAddressRecord> discovered = await addresses.discoverAddressesBatch(
        branch,
        false,
        (_) async => {usedAddress},
        isLegacyDerivation: false,
      );

      expect(_indexes(discovered), List<int>.generate(40, (i) => 45 + i));
    });

    test("continues after the highest change index", () async {
      final List<BitcoinAddressRecord> branch = [
        ..._range(0, 3, isHidden: true),
        _record(9, isHidden: true),
      ];
      final _Addresses addresses = await _addresses(branch);

      final List<BitcoinAddressRecord> discovered = await addresses.discoverAddressesBatch(
        branch,
        true,
        (_) async => <String>{},
        isLegacyDerivation: false,
      );

      expect(_indexes(discovered), List<int>.generate(20, (i) => 10 + i));
      expect(discovered.every((record) => record.isHidden), isTrue);
    });
  });

  group("discoverAddresses", () {
    test("continues after the highest index of a branch with a hole", () async {
      final List<BitcoinAddressRecord> branch = [..._range(0, 22), _record(44)];
      final _Addresses addresses = await _addresses(branch);

      await addresses.discoverAddresses(
        branch,
        false,
        (_) async => null,
        isLegacyDerivation: false,
      );

      expect(_indexes(branch.skip(23)), List<int>.generate(20, (i) => 45 + i));
    });
  });
}
