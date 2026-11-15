import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_message_sign.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/encryption_file_utils.dart";
import "package:cw_core/unspent_coins_info.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final _master = Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));
final _receiveHd = _master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
final _changeHd = _master.derivePath("m/84'/0'/0'/1") as Bip32Slip10Secp256k1;

String _p2wpkh(Bip32Slip10Secp256k1 hd, int index) =>
    generateP2WPKHAddress(hd: hd, network: BitcoinNetwork.mainnet, index: index);

BitcoinAddressRecord _record(
  String address, {
  int index = 0,
  BitcoinAddressType type = SegwitAddresType.p2wpkh,
  bool isHidden = false,
}) =>
    BitcoinAddressRecord(
      address,
      index: index,
      type: type,
      isHidden: isHidden,
      network: BitcoinNetwork.mainnet,
    );

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoUnspentsBox implements Box<UnspentCoinsInfo> {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Addresses extends BitcoinWalletAddresses {
  _Addresses(super.walletInfo, List<BitcoinAddressRecord> records)
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
          initialAddresses: records,
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

ElectrumWallet _wallet(List<BitcoinAddressRecord> records) {
  final walletInfo = WalletInfo.external(
    id: "sign_message_test",
    name: "sign_message_test",
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
  )..walletAddresses = _Addresses(walletInfo, records);
}

void main() {
  group("getSigningAddressRecord", () {
    final receive = _record(_p2wpkh(_receiveHd, 0));
    final change = _record(_p2wpkh(_changeHd, 0), isHidden: true);
    final taproot = _record(
      "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0",
      type: SegwitAddresType.p2tr,
    );
    final mweb = BitcoinAddressRecord(
      "ltcmweb1qqexample",
      index: 0,
      type: SegwitAddresType.mweb,
      network: null,
    );
    final walletAddresses = [receive, change, taproot, mweb];

    test("blank address still uses the main key", () {
      for (final address in [null, "", "   "]) {
        expect(
          getSigningAddressRecord(address: address, walletAddresses: walletAddresses),
          isNull,
        );
      }
      expect(getSigningAddressRecord(address: null, walletAddresses: []), isNull);
    });

    test("refuses an address the wallet does not hold", () {
      expect(
        () => getSigningAddressRecord(
          address: "sp1qqexample",
          walletAddresses: walletAddresses,
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => getSigningAddressRecord(address: receive.address, walletAddresses: []),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test("refuses taproot and MWEB addresses the wallet holds", () {
      for (final record in [taproot, mweb]) {
        expect(
          () => getSigningAddressRecord(address: record.address, walletAddresses: walletAddresses),
          throwsA(isA<UnsupportedError>()),
        );
      }
    });

    test("returns the held record for a receive or change address", () {
      expect(
        getSigningAddressRecord(address: receive.address, walletAddresses: walletAddresses),
        same(receive),
      );
      expect(
        getSigningAddressRecord(address: change.address, walletAddresses: walletAddresses),
        same(change),
      );
    });

    test("ignores whitespace around a pasted address", () {
      expect(
        getSigningAddressRecord(
          address: "  ${receive.address}\n",
          walletAddresses: walletAddresses,
        ),
        same(receive),
      );
    });
  });

  group("ElectrumWallet.signMessage", () {
    setUpAll(() async {
      sqfliteFfiInit();
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db!.execute(
        "CREATE TABLE walletInfoAddress "
        "(walletInfoAddressId INTEGER PRIMARY KEY, walletInfoId INTEGER, type INTEGER, "
        "address TEXT)",
      );
    });

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test("signs receive and change addresses with their own keys", () async {
      final receive = _p2wpkh(_receiveHd, 1);
      final change = _p2wpkh(_changeHd, 1);
      final wallet = _wallet([
        _record(receive, index: 1),
        _record(change, index: 1, isHidden: true),
      ]);

      final receiveSignature = await wallet.signMessage("test", address: receive);
      final changeSignature = await wallet.signMessage("test", address: change);

      expect(await wallet.verifyMessage("test", receiveSignature, address: receive), isTrue);
      expect(await wallet.verifyMessage("test", changeSignature, address: change), isTrue);
      expect(await wallet.verifyMessage("test", changeSignature, address: receive), isFalse);
    });

    test("refuses an address the wallet does not hold", () async {
      final wallet = _wallet([_record(_p2wpkh(_receiveHd, 1), index: 1)]);

      await expectLater(
        wallet.signMessage("test", address: _p2wpkh(_receiveHd, 2)),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
