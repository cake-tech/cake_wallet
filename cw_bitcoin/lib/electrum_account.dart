import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";

class ElectrumAccounts {
  ElectrumAccounts({required List<BitcoinAddressType> primaryTypes})
      : _primaryTypes = List.unmodifiable(primaryTypes);

  final List<BitcoinAddressType> _primaryTypes;
  final Map<int, ElectrumAccount> _byIndex = {};

  List<int> get indexes => _byIndex.keys.toList()..sort();

  ElectrumAccount? operator [](int index) => _byIndex[index];

  ElectrumAccount getOrCreate(int index) => _byIndex.putIfAbsent(
    index,
        () => ElectrumAccount(
      index: index,
      label: index == 0 ? "Primary account" : "Account $index",
      supportedTypes: index == 0 ? _primaryTypes : EXTRA_ACCOUNT_ADDRESS_TYPES,
    ),
  );

  bool contains(int index) => _byIndex.containsKey(index);

  void remove(int index) => _byIndex.remove(index);
}

class ElectrumAccount {
  ElectrumAccount({
    required this.index,
    required this.label,
    required List<BitcoinAddressType> supportedTypes,
  }) : supportedTypes = List.unmodifiable(supportedTypes);

  final int index;
  String label;
  final List<BitcoinAddressType> supportedTypes;
  final AccountHdKeys hd = AccountHdKeys();
}

class AccountHdKeys {
  final Map<BitcoinAddressType, Bip32Slip10Secp256k1> _receive = {};
  final Map<BitcoinAddressType, Bip32Slip10Secp256k1> _change = {};

  void set(
      BitcoinAddressType type, {
        required Bip32Slip10Secp256k1 receive,
        required Bip32Slip10Secp256k1 change,
      }) {
    _receive[type] = receive;
    _change[type] = change;
  }

  Bip32Slip10Secp256k1? receive(BitcoinAddressType type) => _receive[type];

  Bip32Slip10Secp256k1? change(BitcoinAddressType type) => _change[type];

  Bip32Slip10Secp256k1? branch(BitcoinAddressType type, {required bool isChange}) =>
      isChange ? change(type) : receive(type);
}