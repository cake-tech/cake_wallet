import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_core/utils/print_verbose.dart";

class ElectrumAccounts {
  ElectrumAccounts({required List<BitcoinAddressType> primaryTypes})
      : _primaryTypes = List.unmodifiable(primaryTypes);

  final List<BitcoinAddressType> _primaryTypes;
  final Map<int, ElectrumAccount> _byIndex = {};

  List<int> get indexes => _byIndex.keys.toList()..sort();

  ElectrumAccount? operator [](int index) => _byIndex[index];

  Bip32Slip10Secp256k1? hdFor({
    required int accountIndex,
    required BitcoinAddressType type,
    required bool isChange,
    bool isLegacy = false,
  }) =>
      _byIndex[accountIndex]?.hd.branch(type, isChange: isChange, isLegacy: isLegacy);

  ElectrumAccount getOrCreate(int index) {
    final existing = _byIndex[index];
    if (existing != null) return existing;

    final account = ElectrumAccount(
      index: index,
      label: index == 0 ? "Primary account" : "Account $index",
      supportedTypes: index == 0 ? _primaryTypes : EXTRA_ACCOUNT_ADDRESS_TYPES,
    );
    _byIndex[index] = account;
    printV("[ELECTRUM ACCOUNTS] added account $index "
        '(${account.supportedTypes.map((t) => t.value).join('/')}), now $indexes');
    return account;
  }

  bool contains(int index) => _byIndex.containsKey(index);

  void remove(int index) {
    if (_byIndex.remove(index) != null) {
      printV("[ELECTRUM ACCOUNTS] removed account $index, now $indexes");
    }
  }

  @override
  String toString() => 'ElectrumAccounts(${indexes.map((i) => _byIndex[i]).join(',\n')})';
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

  @override
  String toString() =>
      'ElectrumAccount(index: $index, label: $label, types: ${supportedTypes.map((t) => t.value).join('/')}, hd: $hd)';
}

class AccountHdKeys {
  final Map<BitcoinAddressType, Bip32Slip10Secp256k1> _receive = {};
  final Map<BitcoinAddressType, Bip32Slip10Secp256k1> _change = {};

  Bip32Slip10Secp256k1? _legacyReceive;
  Bip32Slip10Secp256k1? _legacyChange;

  void setLegacy({required Bip32Slip10Secp256k1 receive, required Bip32Slip10Secp256k1 change}) {
    _legacyReceive = receive;
    _legacyChange = change;
  }

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

  Bip32Slip10Secp256k1? branch(
    BitcoinAddressType type, {
    required bool isChange,
    bool isLegacy = false,
  }) {
    if (isLegacy) return isChange ? _legacyChange : _legacyReceive;
    return isChange ? _change[type] : _receive[type];
  }

  bool isChangeBranch(Bip32Slip10Secp256k1 hd) =>
      identical(hd, _legacyChange) || _change.values.any((key) => identical(key, hd));

  @override
  String toString() => 'AccountHdKeys(receive: ${_receive.keys.map((t) => t.value).join('/')}, '
      'change: ${_change.keys.map((t) => t.value).join('/')}, '
      "legacy: ${_legacyReceive != null})";
}
