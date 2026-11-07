import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_core/utils/print_verbose.dart";

typedef AccountHdDeriver = AccountHdKeys Function(int index, List<BitcoinAddressType> types);

class ElectrumAccounts {
  ElectrumAccounts({
    required List<BitcoinAddressType> primaryTypes,
    required AccountHdDeriver deriveHd,
    List<BitcoinAddressType> extraTypes = EXTRA_ACCOUNT_ADDRESS_TYPES,
  })  : _primaryTypes = List.unmodifiable(primaryTypes),
        _extraTypes = List.unmodifiable(extraTypes),
        _deriveHd = deriveHd;

  final List<BitcoinAddressType> _primaryTypes;
  final List<BitcoinAddressType> _extraTypes;
  final AccountHdDeriver _deriveHd;
  final Map<int, ElectrumAccount> _byIndex = {};
  final Map<int, AccountHdKeys> _hdByIndex = {};

  List<int> get indexes => _byIndex.keys.toList()..sort();

  ElectrumAccount? operator [](int index) => _byIndex[index];

  Bip32Slip10Secp256k1? hdFor({
    required int accountIndex,
    required BitcoinAddressType type,
    required bool isChange,
    bool isLegacy = false,
  }) =>
      _hdByIndex[accountIndex]?.branch(type, isChange: isChange, isLegacy: isLegacy);

  ElectrumAccount getOrCreate(int index) {
    final existing = _byIndex[index];
    if (existing != null) return existing;

    final account = ElectrumAccount(
      index: index,
      label: index == 0 ? "Primary account" : "Account $index",
      supportedTypes: index == 0 ? _primaryTypes : _extraTypes,
    );

    _hdByIndex[index] = _deriveHd(index, account.supportedTypes);
    _byIndex[index] = account;

    printV("[ELECTRUM ACCOUNTS] added account $index "
        '(${account.supportedTypes.map((t) => t.value).join('/')}), now $indexes');
    return account;
  }

  bool contains(int index) => _byIndex.containsKey(index);

  void remove(int index) {
    _hdByIndex.remove(index);
    if (_byIndex.remove(index) != null) {
      printV("[ELECTRUM ACCOUNTS] removed account $index, now $indexes");
    }
  }

  Bip32Slip10Secp256k1? receiveHd(int index, BitcoinAddressType type) =>
      _hdByIndex[index]?.receive(type);

  bool isLegacyChange(Bip32Slip10Secp256k1 hd) => _hdByIndex[0]?.isLegacyChange(hd) ?? false;

  @override
  String toString() =>
      'ElectrumAccounts(${indexes.map((i) => '${_byIndex[i]} ${_hdByIndex[i]}').join(',\n')})';
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

  @override
  String toString() =>
      'ElectrumAccount(index: $index, label: $label, types: ${supportedTypes.map((t) => t.value).join('/')})';
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

  Bip32Slip10Secp256k1? branch(
    BitcoinAddressType type, {
    required bool isChange,
    bool isLegacy = false,
  }) {
    if (isLegacy) return isChange ? _legacyChange : _legacyReceive;
    return isChange ? _change[type] : _receive[type];
  }

  bool isLegacyChange(Bip32Slip10Secp256k1 hd) => identical(hd, _legacyChange);

  @override
  String toString() => 'AccountHdKeys(receive: ${_receive.keys.map((t) => t.value).join('/')}, '
      'change: ${_change.keys.map((t) => t.value).join('/')}, '
      "legacy: ${_legacyReceive != null})";
}
