import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final _master = Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));
final _receiveHd = _master.derivePath("m/84'/0'/0'/0") as Bip32Slip10Secp256k1;
final _changeHd = _master.derivePath("m/84'/0'/0'/1") as Bip32Slip10Secp256k1;

String _p2wpkh(Bip32Slip10Secp256k1 hd, int index) =>
    generateP2WPKHAddress(hd: hd, network: BitcoinNetwork.mainnet, index: index);

final _receive = [for (var i = 0; i < 5; i++) _p2wpkh(_receiveHd, i)];

// BitcoinWalletAddresses only holds on to the manager; nothing tested here uses Payjoin.
class _NoPayjoin implements PayjoinManager {
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
            for (var i = 0; i < _receive.length; i++)
              BitcoinAddressRecord(
                _receive[i],
                index: i,
                type: SegwitAddresType.p2wpkh,
                network: BitcoinNetwork.mainnet,
              ),
            for (var i = 0; i < 3; i++)
              BitcoinAddressRecord(
                _p2wpkh(_changeHd, i),
                index: i,
                isHidden: true,
                type: SegwitAddresType.p2wpkh,
                network: BitcoinNetwork.mainnet,
              ),
          ],
        );

  // The address book reads back exactly addressesMap; storing it isn't under test.
  @override
  Future<void> saveAddressesInBox() async {}
}

Future<_Addresses> _addresses({String? addressPageType}) async {
  final walletInfo = WalletInfo.external(
    id: "picker_test",
    name: "picker_test",
    type: WalletType.bitcoin,
    isRecovery: false,
    restoreHeight: 0,
    date: DateTime(2026),
    dirPath: "",
    path: "",
    address: "",
  )..addressPageType = addressPageType;

  final addresses = _Addresses(walletInfo);
  // The constructor loads the used/hidden/manual sets without awaiting them; a query issued
  // after those has landed once it returns, so the test can't race them.
  await walletInfo.getManualAddresses();
  return addresses;
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

  test("addressForBuy skips hidden addresses", () async {
    final addresses = await _addresses();
    expect(addresses.addressForBuy, _receive[0]);

    // As the exchange flow does with a swap's refund address.
    addresses.hiddenAddresses.add(_receive[0]);

    expect(addresses.addressForBuy, _receive[1]);
  });

  test("on the Silent Payments page, both an on-chain and the SP address are active", () async {
    final addresses = await _addresses(
      addressPageType: SilentPaymentsAddresType.p2sp.toString(),
    );
    addresses.hiddenAddresses.add(_receive[0]);

    await addresses.updateAddressesInBox();

    expect(addresses.addressesMap[_receive[1]], "Active");
    expect(addresses.addressesMap[addresses.silentAddress.toString()], "Active - Silent Payments");
    expect(addresses.addressesMap.containsKey(_receive[0]), isFalse);
  });

  test("on an on-chain page, Silent Payments is not active", () async {
    final addresses = await _addresses();

    await addresses.updateAddressesInBox();

    expect(addresses.addressesMap[_receive[0]], "Active");
    expect(addresses.addressesMap[addresses.silentAddress.toString()], "Silent Payments");
  });
}
