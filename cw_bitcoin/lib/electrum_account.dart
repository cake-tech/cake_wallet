import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_bitcoin/electrum_account_balance_calculator.dart";
import "package:cw_bitcoin/electrum_balance.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:mobx/mobx.dart";

class ElectrumAccounts {
  ElectrumAccounts({
    required List<BitcoinAddressType> primaryTypes,
    required this.currency,
  }) : _primaryTypes = List.unmodifiable(primaryTypes);

  final List<BitcoinAddressType> _primaryTypes;
  final CryptoCurrency currency;
  final Map<int, ElectrumAccount> _byIndex = {};

  List<int> get indexes => _byIndex.keys.toList()..sort();

  List<ElectrumAccount> get all => [for (final index in indexes) _byIndex[index]!];

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
      initialBalance: ElectrumBalance.zero(currency),
    );
    _byIndex[index] = account;
    printV("[ELECTRUM ACCOUNTS] loaded account $index "
        '(${account.supportedTypes.map((t) => t.value).join('/')}), now $indexes');
    return account;
  }

  bool contains(int index) => _byIndex.containsKey(index);

  void remove(int index) {
    if (_byIndex.remove(index) != null) {
      printV("[ELECTRUM ACCOUNTS] removed account $index, now $indexes");
    }
  }

  void setBalances(Map<int, ElectrumBalance> byAccount) {
    final unknown = byAccount.keys.where((index) => !_byIndex.containsKey(index)).toList();
    if (unknown.isNotEmpty) {
      printV("[ELECTRUM ACCOUNTS] ignoring balances for unknown accounts $unknown");
    }

    runInAction(() {
      for (final account in _byIndex.values) {
        final next = byAccount[account.index];
        account._balance.value = next?.copy() ?? ElectrumBalance.zero(currency);
      }
    });
  }

  void setBalancesFromCoins(Iterable<BitcoinUnspent> coins) =>
      setBalances(AccountBalanceCalculator.fromCoins(coins, currency: currency));

  void setBalancesFromAddressRecords(Iterable<BaseBitcoinAddressRecord> records) =>
      setBalances(AccountBalanceCalculator.fromAddressRecords(records, currency: currency));

  void setBalancesFromTotals({
    Map<int, int> confirmed = const {},
    Map<int, int> unconfirmed = const {},
    Map<int, int> frozen = const {},
  }) =>
      setBalances(AccountBalanceCalculator.fromTotals(
        confirmed: confirmed,
        unconfirmed: unconfirmed,
        frozen: frozen,
        currency: currency,
      ));

  Map<String, String> balancesToJson() => {
        for (final account in all) "${account.index}": account._balance.value.toJSON(),
      };

  static Map<int, ElectrumBalance>? balancesFromJson(Object? source, CryptoCurrency currency) {
    if (source is! Map) return null;

    final balances = <int, ElectrumBalance>{};
    for (final entry in source.entries) {
      final index = int.tryParse(entry.key.toString());
      final balance = ElectrumBalance.fromJSON(entry.value as String?, currency);
      if (index != null && balance != null) balances[index] = balance;
    }
    return balances;
  }

  @override
  String toString() => 'ElectrumAccounts(${all.join(',\n')})';
}

class ElectrumAccount {
  ElectrumAccount({
    required this.index,
    required this.label,
    required List<BitcoinAddressType> supportedTypes,
    required ElectrumBalance initialBalance,
  })  : supportedTypes = List.unmodifiable(supportedTypes),
        _balance = Observable(initialBalance);

  final int index;
  String label;
  final List<BitcoinAddressType> supportedTypes;
  final AccountHdKeys hd = AccountHdKeys();

  final Observable<ElectrumBalance> _balance;

  ElectrumBalance get balance => _balance.value.copy();

  bool supports(BitcoinAddressType type) => supportedTypes.contains(type);

  @override
  String toString() {
    final b = _balance.value;
    return "ElectrumAccount(index: $index, label: $label, "
        'types: ${supportedTypes.map((t) => t.value).join('/')}, '
        "balance: c=${b.confirmed} u=${b.unconfirmed} f=${b.frozen}, "
        "hd: $hd)";
  }
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

  @override
  String toString() => 'AccountHdKeys(receive: ${_receive.keys.map((t) => t.value).join('/')}, '
      'change: ${_change.keys.map((t) => t.value).join('/')}, '
      "legacy: ${_legacyReceive != null})";
}
