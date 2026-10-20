import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_wallet_addresses.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/litecoin_wallet_addresses.dart";
import "package:cw_bitcoin/payjoin/manager.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final _master = Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));

Bip32Slip10Secp256k1 _hd(String path) => _master.derivePath(path) as Bip32Slip10Secp256k1;

final _receiveHd = _hd("m/84'/0'/0'/0");
final _changeHd = _hd("m/84'/0'/0'/1");
final _receive = [
  for (var i = 0; i < 5; i++)
    generateP2WPKHAddress(hd: _receiveHd, network: BitcoinNetwork.mainnet, index: i),
];

final _ltcReceiveHd = _hd("m/84'/2'/0'/0");
final _ltcChangeHd = _hd("m/84'/2'/0'/1");
final _ltcReceive = [
  for (var i = 0; i < 5; i++)
    generateP2WPKHAddress(hd: _ltcReceiveHd, network: LitecoinNetwork.mainnet, index: i),
];
const _mweb = "ltcmweb1-placeholder";

List<BitcoinAddressRecord> _records(List<String> receive, BasedUtxoNetwork network) => [
      for (var i = 0; i < receive.length; i++)
        BitcoinAddressRecord(
          receive[i],
          index: i,
          type: SegwitAddresType.p2wpkh,
          network: network,
        ),
    ];

class _NoPayjoin implements PayjoinManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _BitcoinAddresses extends BitcoinWalletAddresses {
  _BitcoinAddresses(super.walletInfo)
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
            ..._records(_receive, BitcoinNetwork.mainnet),
            for (var i = 0; i < 3; i++)
              BitcoinAddressRecord(
                generateP2WPKHAddress(hd: _changeHd, network: BitcoinNetwork.mainnet, index: i),
                index: i,
                isHidden: true,
                type: SegwitAddresType.p2wpkh,
                network: BitcoinNetwork.mainnet,
              ),
          ],
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

class _LitecoinAddresses extends LitecoinWalletAddresses {
  _LitecoinAddresses(super.walletInfo)
      : super(
          mainHdByTypeAndAccount: {
            0: {SegwitAddresType.p2wpkh: _ltcReceiveHd, SegwitAddresType.mweb: _ltcReceiveHd},
          },
          sideHdByTypeAndAccount: {
            0: {SegwitAddresType.p2wpkh: _ltcChangeHd, SegwitAddresType.mweb: _ltcChangeHd},
          },
          accountIndexes: [0],
          currentAccountIndex: 0,
          legacyMainHd: _ltcReceiveHd,
          legacySideHd: _ltcChangeHd,
          network: LitecoinNetwork.mainnet,
          isHardwareWallet: false,
          mwebHd: null,
          mwebEnabled: true,
          scanSecretOverride: null,
          spendPubkeyOverride: null,
          initialAddresses: [
            ..._records(_ltcReceive, LitecoinNetwork.mainnet),
            BitcoinAddressRecord(
              _mweb,
              index: 0,
              type: SegwitAddresType.mweb,
              network: LitecoinNetwork.mainnet,
            ),
          ],
        );

  @override
  Future<void> saveAddressesInBox() async {}
}

WalletInfo _walletInfo(WalletType type, BitcoinAddressType? addressPageType) => WalletInfo.external(
      id: "picker_test",
      name: "picker_test",
      type: type,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "",
    )..addressPageType = addressPageType?.toString();

Future<T> _ready<T extends ElectrumWalletAddresses>(T addresses) async {
  // Lets the constructor's un-awaited used/hidden/manual loads land before the test edits them.
  await addresses.walletInfo.getManualAddresses();
  return addresses;
}

Future<_BitcoinAddresses> _bitcoin({BitcoinAddressType? addressPageType}) =>
    _ready(_BitcoinAddresses(_walletInfo(WalletType.bitcoin, addressPageType)));

Future<_LitecoinAddresses> _litecoin({BitcoinAddressType? addressPageType}) =>
    _ready(_LitecoinAddresses(_walletInfo(WalletType.litecoin, addressPageType)));

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
    final addresses = await _bitcoin();
    expect(addresses.addressForBuy, _receive[0]);

    addresses.hiddenAddresses.add(_receive[0]);

    expect(addresses.addressForBuy, _receive[1]);
  });

  test("on the Silent Payments page, the SegWit address is active", () async {
    final addresses = await _bitcoin(addressPageType: SilentPaymentsAddresType.p2sp);
    addresses.hiddenAddresses.add(_receive[0]);

    await addresses.updateAddressesInBox();

    expect(addresses.address, addresses.silentAddress.toString());
    expect(addresses.addressesMap[_receive[1]], "Active");
    expect(addresses.addressesMap[addresses.silentAddress.toString()], "Silent Payments");
    expect(addresses.addressesMap.containsKey(_receive[0]), isFalse);
  });

  test("on the MWEB page, the regular Litecoin address is active and used for buy", () async {
    final addresses = await _litecoin(addressPageType: SegwitAddresType.mweb);
    addresses.hiddenAddresses.add(_ltcReceive[0]);

    await addresses.updateAddressesInBox();

    expect(addresses.address, _mweb);
    expect(addresses.addressForBuy, _ltcReceive[1]);
    expect(addresses.addressesMap[_ltcReceive[1]], "Active");
    expect(addresses.addressesMap[_mweb], "MWEB");
    expect(addresses.addressesMap.containsKey(_ltcReceive[0]), isFalse);
  });

  test("on the Litecoin SegWit page, its own address stays active", () async {
    final addresses = await _litecoin();

    await addresses.updateAddressesInBox();

    expect(addresses.addressForBuy, addresses.address);
    expect(addresses.addressesMap[_ltcReceive[0]], "Active");
    expect(addresses.addressesMap[_mweb], "MWEB");
  });
}
