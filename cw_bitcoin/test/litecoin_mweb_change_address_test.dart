import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/electrum_account.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_bitcoin/litecoin_wallet_addresses.dart";
import "package:cw_core/db/sqlite.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final _master = Bip32Slip10Secp256k1.fromSeed(List<int>.generate(64, (i) => i));

Bip32Slip10Secp256k1 _derive(String path) => _master.derivePath(path) as Bip32Slip10Secp256k1;

final _accountHd = _derive("m/84'/2'/0'");

const _mwebChange = "mweb_change";

WalletInfo _walletInfo() => WalletInfo.external(
      id: "litecoin_mweb_change_test",
      name: "litecoin_mweb_change_test",
      type: WalletType.litecoin,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime(2026),
      dirPath: "",
      path: "",
      address: "",
    );

ElectrumAccounts _accounts() {
  final accounts = ElectrumAccounts(primaryTypes: LITECOIN_ADDRESS_TYPES);
  final account = accounts.getOrCreate(0);
  for (final type in account.supportedTypes) {
    account.hd.set(
      type,
      receive: _derive("m/84'/2'/0'/0"),
      change: _derive("m/84'/2'/0'/1"),
    );
  }
  account.hd.setLegacy(
    receive: _accountHd.childKey(Bip32KeyIndex(0)),
    change: _accountHd.childKey(Bip32KeyIndex(1)),
  );
  return accounts;
}

LitecoinWalletAddresses _addresses(ElectrumAccounts accounts) {
  final addresses = LitecoinWalletAddresses(
    _walletInfo(),
    accounts: accounts,
    network: LitecoinNetwork.mainnet,
    isHardwareWallet: false,
    mwebHd: null,
    mwebEnabled: false,
    scanSecretOverride: null,
    spendPubkeyOverride: null,
    initialAddresses: [],
  );
  addresses.mwebAddrs
    ..clear()
    ..add(_mwebChange)
    ..addAll([for (var i = 0; i < 30; i++) "mweb_receive_$i"]);
  return addresses;
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db!.execute("CREATE TABLE walletInfoAddress "
        "(walletInfoAddressId INTEGER PRIMARY KEY, walletInfoId INTEGER, type INTEGER, "
        "address TEXT)");
  });

  test("standard MWEB change key does not map to the MWEB change address", () {
    final accounts = _accounts();
    final addresses = _addresses(accounts);
    final changeHd = accounts.hdFor(
      accountIndex: 0,
      type: SegwitAddresType.mweb,
      isChange: true,
    )!;

    final address = addresses.getAddress(
      index: 0,
      hd: changeHd,
      addressType: SegwitAddresType.mweb,
    );

    expect(address, "mweb_receive_0");
  });

  test("legacy change key maps to the MWEB change address", () {
    final accounts = _accounts();
    final addresses = _addresses(accounts);
    final legacyChangeHd = accounts.hdFor(
      accountIndex: 0,
      type: SegwitAddresType.mweb,
      isChange: true,
      isLegacy: true,
    )!;

    final address = addresses.getAddress(
      index: 0,
      hd: legacyChangeHd,
      addressType: SegwitAddresType.mweb,
    );

    expect(address, _mwebChange);
  });
}
