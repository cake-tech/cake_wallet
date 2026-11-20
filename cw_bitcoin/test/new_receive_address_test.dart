// "New address" on the Receive page (WalletAddressListViewModel.rotateAddress, which calls
// ElectrumWalletAddresses.generateNewAddress) hands out the unused addresses sync already derived,
// in order, before deriving new ones. Deriving after all of them, as it did, jumped past the gap a
// seed restore scans (BIP44: 20 unused addresses past the last used one). It never shows the same
// address twice.
import "dart:math";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/lightning/lightning_addres_type.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

const int _gap = ElectrumWalletAddressesBase.gap;

final Bip32Slip10Secp256k1 _master =
    Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));

final Map<String, Bip32Slip10Secp256k1> _hds = {};

Bip32Slip10Secp256k1 _hd(String path) =>
    _hds[path] ??= _master.derivePath(path) as Bip32Slip10Secp256k1;

const List<BitcoinAddressType> _types = [
  SegwitAddresType.p2wpkh,
  P2pkhAddressType.p2pkh,
  SegwitAddresType.p2tr,
  SegwitAddresType.mweb,
];

final Map<BitcoinAddressType, int> _purposes = {
  P2pkhAddressType.p2pkh: 44,
  SegwitAddresType.p2tr: 86,
  SegwitAddresType.mweb: 1000,
};

/// The wallet's own receive chain of [type] and [account], or its change chain.
Bip32Slip10Secp256k1 _chain(BitcoinAddressType type, {int account = 0, bool change = false}) =>
    _hd("m/${_purposes[type] ?? 84}'/0'/$account'/${change ? 1 : 0}");

final Bip32Slip10Secp256k1 _legacyReceiveHd = _hd("m/0'/0");
final Bip32Slip10Secp256k1 _legacyChangeHd = _hd("m/0'/1");

String _addressOn(Bip32Slip10Secp256k1 hd, BitcoinAddressType type, int index) {
  if (type == P2pkhAddressType.p2pkh) {
    return generateP2PKHAddress(hd: hd, index: index, network: BitcoinNetwork.mainnet);
  }
  if (type == SegwitAddresType.p2tr) {
    return generateP2TRAddress(hd: hd, index: index, network: BitcoinNetwork.mainnet);
  }
  return generateP2WPKHAddress(hd: hd, index: index, network: BitcoinNetwork.mainnet);
}

/// The receive address the wallet derives at [index].
String _receiveAddress(
  int index, {
  BitcoinAddressType type = SegwitAddresType.p2wpkh,
  int account = 0,
}) =>
    _addressOn(_chain(type, account: account), type, index);

BitcoinAddressRecord _record(
  int index, {
  BitcoinAddressType type = SegwitAddresType.p2wpkh,
  int account = 0,
  bool isChange = false,
  bool isLegacyDerivation = false,
  bool legacyOnSameChain = false,
  bool isUsed = false,
  String name = "",
}) =>
    BitcoinAddressRecord(
      _addressOn(
        isLegacyDerivation && !legacyOnSameChain
            ? (isChange ? _legacyChangeHd : _legacyReceiveHd)
            : _chain(type, account: account, change: isChange),
        type,
        index,
      ),
      index: index,
      type: type,
      accountIndex: account,
      isHidden: isChange,
      isLegacyDerivation: isLegacyDerivation,
      isUsed: isUsed,
      name: name,
      network: BitcoinNetwork.mainnet,
    );

/// Receive addresses 0 to [count] - 1 as sync leaves them: the [used] ones have history.
List<BitcoinAddressRecord> _receiveBranch(
  int count, {
  Set<int> used = const {},
  BitcoinAddressType type = SegwitAddresType.p2wpkh,
  int account = 0,
  Map<int, String> labels = const {},
}) =>
    [
      for (var i = 0; i < count; i++)
        _record(i, type: type, account: account, isUsed: used.contains(i), name: labels[i] ?? ""),
    ];

List<BitcoinAddressRecord> _changeBranch(int count, {Set<int> used = const {}}) => [
      for (var i = 0; i < count; i++) _record(i, isChange: true, isUsed: used.contains(i)),
    ];

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Addresses extends BitcoinWalletAddresses {
  _Addresses(
    super.walletInfo, {
    required List<BitcoinAddressRecord> records,
    required bool legacyIsSameChain,
    super.masterHd,
  }) : super(
          mainHdByTypeAndAccount: {
            0: {for (final type in _types) type: _chain(type)},
            1: {SegwitAddresType.p2wpkh: _chain(SegwitAddresType.p2wpkh, account: 1)},
          },
          sideHdByTypeAndAccount: {
            0: {for (final type in _types) type: _chain(type, change: true)},
            1: {
              SegwitAddresType.p2wpkh: _chain(SegwitAddresType.p2wpkh, account: 1, change: true),
            },
          },
          accountIndexes: [0, 1],
          currentAccountIndex: 0,
          legacyMainHd: legacyIsSameChain ? _chain(SegwitAddresType.p2wpkh) : _legacyReceiveHd,
          legacySideHd:
              legacyIsSameChain ? _chain(SegwitAddresType.p2wpkh, change: true) : _legacyChangeHd,
          network: BitcoinNetwork.mainnet,
          isHardwareWallet: false,
          payjoinManager: _NoPayjoin(),
          initialAddresses: records,
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

Future<_Addresses> _wallet(
  List<BitcoinAddressRecord> records, {
  BitcoinAddressType page = SegwitAddresType.p2wpkh,
  WalletType walletType = WalletType.bitcoin,
  bool withSilentPayments = false,
  bool legacyIsSameChain = false,
}) async {
  final WalletInfo walletInfo = WalletInfo.external(
    id: "new_receive_address_test",
    name: "new_receive_address_test",
    type: walletType,
    isRecovery: false,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: "",
  )..addressPageType = page.toString();

  final _Addresses addresses = _Addresses(
    walletInfo,
    records: records,
    legacyIsSameChain: legacyIsSameChain,
    masterHd: withSilentPayments ? _master : null,
  );
  // The constructor loads the used, hidden and manual addresses; let that finish first.
  await walletInfo.getManualAddresses();
  return addresses;
}

/// What opening the Receive page does (WalletAddressListViewModel._init).
void _openReceivePage(_Addresses addresses) => addresses.address = addresses.latestAddress;

BitcoinAddressRecord _onScreen(_Addresses addresses) =>
    addresses.allAddresses.firstWhere((record) => record.address == addresses.address);

/// What the Receive page's rotate button does (WalletAddressListViewModel.rotateAddress): create an
/// address, wait for the wallet to save, which lets a derived address join the list, then show the
/// address that came back.
Future<BitcoinAddressRecord> _tapNewAddress(_Addresses addresses) async {
  final BitcoinAddressRecord record = addresses.generateNewAddress() as BitcoinAddressRecord;
  await Future<void>.delayed(Duration.zero);
  addresses.address = record.address;
  return record;
}

Future<List<int>> _tap(_Addresses addresses, int times) async => [
      for (var i = 0; i < times; i++) (await _tapNewAddress(addresses)).index,
    ];

/// What saving a new address with a label does (WalletAddressEditOrCreateViewModel): create it
/// without showing it.
Future<BitcoinAddressRecord> _createLabelledAddress(_Addresses addresses, String label) async {
  final BitcoinAddressRecord record =
      addresses.generateNewAddress(label: label) as BitcoinAddressRecord;
  await Future<void>.delayed(Duration.zero);
  return record;
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

  group("hands out the next free address after the one on screen", () {
    test("new wallet: receive/1, 2 and 3 after receive/0", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(22));
      _openReceivePage(addresses);
      expect(_onScreen(addresses).index, 0);

      expect(await _tap(addresses, 3), [1, 2, 3]);
      expect(addresses.address, _receiveAddress(3));
      expect(addresses.allAddresses, hasLength(22));
    });

    test("restored wallet with receive/0 used: receive/2 and 3 after receive/1", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0}));
      _openReceivePage(addresses);
      expect(_onScreen(addresses).index, 1);

      expect(await _tap(addresses, 2), [2, 3]);
      expect(addresses.allAddresses, hasLength(42));
    });

    test("receive/0 and receive/22 used, 62 stored: receive/2 and 3, not 62 and 63", () async {
      final _Addresses addresses = await _wallet([
        ..._receiveBranch(62, used: {0, 22}),
        ..._changeBranch(17, used: {0, 1}),
      ]);
      _openReceivePage(addresses);
      expect(_onScreen(addresses).index, 1);

      final BitcoinAddressRecord first = await _tapNewAddress(addresses);
      final BitcoinAddressRecord second = await _tapNewAddress(addresses);

      expect([first.index, second.index], [2, 3]);
      expect(first.address, _receiveAddress(2));
      expect(second.address, _receiveAddress(3));
      expect(first.isHidden, isFalse);
      expect(addresses.allAddresses, hasLength(62 + 17));
    });

    test("skips used addresses", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0, 2, 3, 5}));
      _openReceivePage(addresses);
      expect(_onScreen(addresses).index, 1);

      expect(await _tap(addresses, 3), [4, 6, 7]);
    });
  });

  group("never shows an address twice", () {
    test("when the stored unused addresses run out, derives new ones instead of starting over",
        () async {
      final _Addresses addresses = await _wallet(_receiveBranch(22));
      _openReceivePage(addresses);

      expect(await _tap(addresses, 23), [for (var i = 1; i <= 23; i++) i]);
      expect(addresses.allAddresses, hasLength(24));
      expect(addresses.address, _receiveAddress(23));
    });

    test("100 taps on the wallet with receive/0 and 22 used: every address once, in order",
        () async {
      final _Addresses addresses = await _wallet(_receiveBranch(62, used: {0, 22}));
      _openReceivePage(addresses);

      final List<int> indexes = await _tap(addresses, 100);

      expect(indexes, [
        for (var i = 2; i <= 102; i++)
          if (i != 22) i,
      ]);
      expect(indexes[39], 22 + _gap, reason: "the first 40 stay within 20 of receive/22");
      expect(addresses.allAddresses, hasLength(103));
    });

    test("putting an older address on screen doesn't make new address go back", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0}));
      _openReceivePage(addresses);
      expect(await _tap(addresses, 4), [2, 3, 4, 5]);

      addresses.address = _receiveAddress(2); // picked in the address list

      expect(await _tap(addresses, 2), [6, 7]);
    });

    test("a payment to the address on screen doesn't make new address go back", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0}));
      _openReceivePage(addresses);
      expect(await _tap(addresses, 4), [2, 3, 4, 5]);

      _onScreen(addresses).setAsUsed();

      expect(await _tap(addresses, 2), [6, 7]);
    });

    test("two taps before the screen updates give two different addresses", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0}));
      _openReceivePage(addresses);

      final BaseBitcoinAddressRecord first = addresses.generateNewAddress();
      final BaseBitcoinAddressRecord second = addresses.generateNewAddress();

      expect([first.index, second.index], [2, 3]);
      expect(addresses.allAddresses, hasLength(42));
    });

    test("derives the next index once the stored addresses run out", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(3, used: {0}));
      _openReceivePage(addresses);

      expect(await _tap(addresses, 3), [2, 3, 4]);
      expect(addresses.allAddresses.map((record) => record.index), [0, 1, 2, 3, 4]);
      expect(addresses.address, _receiveAddress(4));
    });

    test("putting an older address on screen after deriving new ones doesn't go back", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(3, used: {0}));
      _openReceivePage(addresses);
      expect(await _tap(addresses, 3), [2, 3, 4]);

      addresses.address = _receiveAddress(2); // picked in the address list

      expect(await _tap(addresses, 1), [5]);
    });

    test("an empty wallet derives receive/0, then 1", () async {
      final _Addresses addresses = await _wallet(<BitcoinAddressRecord>[]);

      expect(await _tap(addresses, 2), [0, 1]);
      expect(addresses.address, _receiveAddress(1));
    });

    test("with every address used, derives the next one as before", () async {
      final _Addresses addresses = await _wallet(
        _receiveBranch(22, used: {for (var i = 0; i < 22; i++) i}),
      );

      final BitcoinAddressRecord record = await _tapNewAddress(addresses);

      expect(record.index, 22);
      expect(record.address, _receiveAddress(22));
      expect(await _tap(addresses, 1), [23]);
      expect(addresses.allAddresses, hasLength(24));
    });
  });

  group("user actions", () {
    test("labelled addresses stay with whoever they were labelled for", () async {
      final _Addresses addresses =
          await _wallet(_receiveBranch(42, used: {0}, labels: {2: "Alice", 3: "Bob"}));
      _openReceivePage(addresses);

      expect(await _tap(addresses, 2), [4, 5]);
    });

    test("a new labelled address takes the next free address", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(62, used: {0, 22}));
      _openReceivePage(addresses);
      var listUpdates = 0;
      final ReactionDisposer stopWatching = reaction(
        (_) => addresses.addressesByReceiveType.toList(),
        (_) => listUpdates++,
      );

      final BitcoinAddressRecord labelled = await _createLabelledAddress(addresses, "Carol");
      stopWatching();

      expect(labelled.index, 2);
      expect(labelled.name, "Carol");
      expect(labelled.address, _receiveAddress(2));
      expect(listUpdates, greaterThan(0), reason: "the address list shows the new label");
      expect(addresses.allAddresses, hasLength(62));
      expect(_onScreen(addresses).index, 1, reason: "the Receive page keeps its address");
      expect(await _tap(addresses, 2), [3, 4]);
    });

    test("addresses the user hid are skipped", () async {
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0}));
      addresses.hiddenAddresses.addAll([_receiveAddress(2), _receiveAddress(3)]);
      _openReceivePage(addresses);

      expect(await _tap(addresses, 2), [4, 5]);
    });

    test("a long run of labelled and hidden addresses is skipped", () async {
      final _Addresses addresses = await _wallet(
        _receiveBranch(
          42,
          used: {0},
          labels: {for (var i = 1; i <= 18; i++) i: "label $i"},
        ),
      );
      addresses.hiddenAddresses.addAll([_receiveAddress(19), _receiveAddress(20)]);

      final BitcoinAddressRecord record = await _tapNewAddress(addresses);

      expect(record.index, 21);
      expect(addresses.allAddresses, hasLength(42));
    });

    test("after switching the address type, starts from the address shown for that type", () async {
      // Switching type (setAddressType) leaves the address set last as it was. The test database
      // has no table for setAddressType to save the wallet to, so open the Taproot page with a
      // SegWit address set instead.
      final _Addresses addresses = await _wallet(
        [
          ..._receiveBranch(42, used: {0}),
          ..._receiveBranch(22, type: SegwitAddresType.p2tr, used: {0}),
        ],
        page: SegwitAddresType.p2tr,
      );
      addresses.address = _receiveAddress(5);
      expect(_onScreen(addresses).type, SegwitAddresType.p2tr);
      expect(_onScreen(addresses).index, 1);

      final BitcoinAddressRecord record = await _tapNewAddress(addresses);

      expect(record.type, SegwitAddresType.p2tr);
      expect(record.index, 2);
      expect(record.address, _receiveAddress(2, type: SegwitAddresType.p2tr));
    });

    test("after switching account, starts from the address shown for that account", () async {
      final _Addresses addresses = await _wallet([
        ..._receiveBranch(42, used: {0}),
        ..._receiveBranch(22, account: 1, used: {0}),
      ]);
      _openReceivePage(addresses);
      expect(await _tap(addresses, 3), [2, 3, 4]);

      // What ElectrumWallet.setCurrentAccount changes for the addresses.
      addresses.currentAccountIndex = 1;
      expect(_onScreen(addresses).accountIndex, 1);
      expect(_onScreen(addresses).index, 1);

      final BitcoinAddressRecord record = await _tapNewAddress(addresses);

      expect(record.accountIndex, 1);
      expect(record.index, 2);
      expect(record.address, _receiveAddress(2, account: 1));

      // Back on the first account, it goes on after the addresses handed out there.
      addresses.currentAccountIndex = 0;
      expect(await _tap(addresses, 1), [5]);
    });
  });

  group("other address pages keep their behaviour", () {
    test("MWEB derives a new address, as MWEB addresses aren't found by the gap", () async {
      final _Addresses addresses = await _wallet(
        _receiveBranch(22, type: SegwitAddresType.mweb),
        page: SegwitAddresType.mweb,
        walletType: WalletType.litecoin,
      );
      _openReceivePage(addresses);

      final BitcoinAddressRecord record = await _tapNewAddress(addresses);

      expect(record.type, SegwitAddresType.mweb);
      expect(record.index, 22);
      expect(addresses.allAddresses, hasLength(23));
    });

    test("Silent Payments adds a silent payment address, and the Receive page shows it", () async {
      final _Addresses addresses = await _wallet(
        _receiveBranch(22),
        page: SilentPaymentsAddresType.p2sp,
        withSilentPayments: true,
      );
      final int silentAddressCount = addresses.silentAddresses.length;

      final BaseBitcoinAddressRecord record = addresses.generateNewAddress();
      // The rotate button now shows the address that came back.
      addresses.address = record.address;

      expect(record, isA<BitcoinSilentPaymentAddressRecord>());
      expect(record.type, SilentPaymentsAddresType.p2sp);
      expect(addresses.silentAddresses, hasLength(silentAddressCount + 1));
      expect(addresses.allAddresses, hasLength(22));
      expect(addresses.address, record.address);
    });

    test("Lightning still refuses to rotate", () async {
      final _Addresses addresses =
          await _wallet(_receiveBranch(22), page: LightningAddressType.p2l);

      expect(addresses.generateNewAddress, throwsArgumentError);
    });

    test("legacy derivation addresses are never handed out", () async {
      final _Addresses addresses = await _wallet(
        [
          ..._receiveBranch(2, type: P2pkhAddressType.p2pkh, used: {0}),
          for (var i = 0; i < 22; i++)
            _record(i, type: P2pkhAddressType.p2pkh, isLegacyDerivation: true),
        ],
        page: P2pkhAddressType.p2pkh,
      );
      _openReceivePage(addresses);

      final BitcoinAddressRecord record = await _tapNewAddress(addresses);

      expect(record.isLegacyDerivation, isFalse);
      expect(record.index, 2);
      expect(record.address, _receiveAddress(2, type: P2pkhAddressType.p2pkh));
    });

    test("legacy addresses with the same keys aren't handed out, and new indexes skip them",
        () async {
      // With the same keys, the legacy derivation's records are the same addresses.
      final _Addresses addresses = await _wallet(
        [
          ..._receiveBranch(3, used: {0}),
          for (var i = 3; i <= 25; i++)
            _record(i, isLegacyDerivation: true, legacyOnSameChain: true, isUsed: i == 25),
        ],
        legacyIsSameChain: true,
      );
      _openReceivePage(addresses);

      expect(await _tap(addresses, 2), [2, 26]);
      expect(addresses.address, _receiveAddress(26));
    });
  });

  group("Litecoin, Bitcoin Cash and Dogecoin share the logic", () {
    for (final (walletType, type) in <(WalletType, BitcoinAddressType)>[
      (WalletType.litecoin, SegwitAddresType.p2wpkh),
      (WalletType.bitcoinCash, P2pkhAddressType.p2pkh),
      (WalletType.dogecoin, P2pkhAddressType.p2pkh),
    ]) {
      test("$walletType: receive/2 and 3 after receive/1 with receive/0 and 22 used", () async {
        final _Addresses addresses = await _wallet(
          _receiveBranch(62, type: type, used: {0, 22}),
          page: type,
          walletType: walletType,
        );
        _openReceivePage(addresses);
        expect(_onScreen(addresses).index, 1);

        expect(await _tap(addresses, 2), [2, 3]);
        expect(addresses.allAddresses, hasLength(62));
      });
    }
  });

  test("random taps, payments, labels, hidden and picked addresses never repeat one", () async {
    for (var seed = 0; seed < 25; seed++) {
      final Random random = Random(seed);
      final _Addresses addresses = await _wallet(_receiveBranch(42, used: {0}));
      _openReceivePage(addresses);
      var onScreen = _onScreen(addresses).index;
      var highestHandedOut = -1;
      final Set<String> handedOut = {};
      var labels = 0;
      var hidden = 0;

      // The address the wallet should hand out next: the lowest free stored one past both the
      // address on screen and every one handed out, or null when a new index has to be derived.
      BitcoinAddressRecord? expectedNext() {
        final int after = max(onScreen, highestHandedOut);
        final List<BitcoinAddressRecord> free = addresses.allAddresses
            .where(
              (record) =>
                  !record.isHidden &&
                  !record.isUsed &&
                  record.name.isEmpty &&
                  !addresses.hiddenAddresses.contains(record.address) &&
                  record.index > after,
            )
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        return free.isEmpty ? null : free.first;
      }

      Future<BitcoinAddressRecord> handOut(String where, {String? label}) async {
        final BitcoinAddressRecord? expected = expectedNext();
        final int stored = addresses.allAddresses.length;
        final int highestStored = addresses.allAddresses.map((record) => record.index).reduce(max);

        final BitcoinAddressRecord record = label == null
            ? await _tapNewAddress(addresses)
            : await _createLabelledAddress(addresses, label);

        expect(handedOut, isNot(contains(record.address)), reason: where);
        expect(record.isUsed, isFalse, reason: where);
        expect(addresses.hiddenAddresses, isNot(contains(record.address)), reason: where);
        if (expected != null) {
          expect(record.index, expected.index, reason: where);
          expect(addresses.allAddresses, hasLength(stored), reason: where);
        } else {
          expect(record.index, highestStored + 1, reason: where);
          expect(addresses.allAddresses, hasLength(stored + 1), reason: where);
        }
        handedOut.add(record.address);
        highestHandedOut = max(highestHandedOut, record.index);
        return record;
      }

      for (var step = 0; step < 150; step++) {
        final String where = "seed $seed, step $step";
        final int roll = random.nextInt(20);
        if (roll < 10) {
          onScreen = (await handOut(where)).index;
        } else if (roll < 13) {
          _onScreen(addresses).setAsUsed();
        } else if (roll < 15) {
          final List<BitcoinAddressRecord> older = addresses.allAddresses
              .where((record) => handedOut.contains(record.address) && !record.isUsed)
              .toList();
          if (older.isNotEmpty) {
            final BitcoinAddressRecord picked = older[random.nextInt(older.length)];
            addresses.address = picked.address;
            onScreen = picked.index;
          }
        } else if (roll == 15 && labels < 3) {
          labels++;
          final BitcoinAddressRecord record = await handOut(where, label: "label $labels");
          expect(record.name, "label $labels", reason: where);
        } else if (roll == 16 && hidden < 3) {
          hidden++;
          final List<BitcoinAddressRecord> unused =
              addresses.allAddresses.where((record) => !record.isUsed).toList();
          addresses.hiddenAddresses.add(unused[random.nextInt(unused.length)].address);
        } else {
          onScreen = (await handOut(where)).index;
        }
      }
    }
  });
}
