import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_bitcoin/electrum_account_balance_calculator.dart";
import "package:cw_bitcoin/electrum_balance.dart";
import "package:cw_bitcoin/electrum_wallet_addresses.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:mobx/mobx.dart";

int purposeForType(BitcoinAddressType type) {
  switch (type.value) {
    case "P2PKH":
      return 44;
    case "P2SH/P2WPKH":
      return 49;
    case "P2WPKH":
      return 84;
    case "P2TR":
      return 86;
    default:
      return 84;
  }
}

class ElectrumAccounts {
  ElectrumAccounts({
    required List<BitcoinAddressType> primaryTypes,
    required this.currency,
    required Bip32Slip10Secp256k1 accountHd,
    Bip32Slip10Secp256k1? masterHd,
    int? coinType,
    List<BitcoinAddressType> extraTypes = EXTRA_ACCOUNT_ADDRESS_TYPES,
  })  : _primaryTypes = List.unmodifiable(primaryTypes),
        _extraTypes = List.unmodifiable(extraTypes),
        _accountHd = accountHd,
        _masterHd = masterHd,
        _coinType = coinType;

  final List<BitcoinAddressType> _primaryTypes;
  final List<BitcoinAddressType> _extraTypes;
  final CryptoCurrency currency;
  final Bip32Slip10Secp256k1 _accountHd;
  final Bip32Slip10Secp256k1? _masterHd;
  final int? _coinType;
  final ObservableMap<int, ElectrumAccount> _byIndex = ObservableMap<int, ElectrumAccount>();
  final Map<int, AccountHdKeys> _hdByIndex = {};

  List<int> get indexes => _byIndex.keys.toList()..sort();

  List<ElectrumAccount> get all =>
      _byIndex.values.toList()..sort((a, b) => a.index.compareTo(b.index));

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
      initialBalance: ElectrumBalance.zero(currency),
    );

    _hdByIndex[index] = _deriveHd(index, account.supportedTypes);
    runInAction(() => _byIndex[index] = account);

    printV("[ELECTRUM ACCOUNTS] added account $index "
        '(${account.supportedTypes.map((t) => t.value).join('/')}), now $indexes');
    return account;
  }

  bool contains(int index) => _byIndex.containsKey(index);

  void remove(int index) {
    _hdByIndex.remove(index);
    final removed = runInAction(() => _byIndex.remove(index));
    if (removed != null) {
      printV("[ELECTRUM ACCOUNTS] removed account $index, now $indexes");
    }
  }

  Bip32Slip10Secp256k1? receiveHd(int index, BitcoinAddressType type) =>
      _hdByIndex[index]?.receive(type);

  bool isLegacyChange(Bip32Slip10Secp256k1 hd) => _hdByIndex[0]?.isLegacyChange(hd) ?? false;

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

  AccountHdKeys _deriveHd(int index, List<BitcoinAddressType> types) {
    final hd = AccountHdKeys();
    final masterHd = _masterHd;
    final coinType = _coinType;

    if (masterHd != null && coinType != null) {
      final accountHdByPath = <String, Bip32Slip10Secp256k1>{};

      for (final type in types) {
        final accountPath = "m/${purposeForType(type)}'/$coinType'/$index'";
        final accountHd = accountHdByPath[accountPath] ??=
            masterHd.derivePath(accountPath) as Bip32Slip10Secp256k1;

        hd.set(
          type,
          receive: accountHd.childKey(Bip32KeyIndex(0)),
          change: accountHd.childKey(Bip32KeyIndex(1)),
        );
      }
    } else {
      for (final type in types) {
        hd.set(
          type,
          receive: _accountHd.childKey(Bip32KeyIndex(0)),
          change: _accountHd.childKey(Bip32KeyIndex(1)),
        );
      }
    }

    if (index == 0) {
      hd.setLegacy(
        receive: _accountHd.childKey(Bip32KeyIndex(0)),
        change: _accountHd.childKey(Bip32KeyIndex(1)),
      );
    }

    return hd;
  }

  @override
  String toString() =>
      'ElectrumAccounts(${indexes.map((i) => '${_byIndex[i]} ${_hdByIndex[i]}').join(',\n')})';
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

  final Observable<ElectrumBalance> _balance;

  ElectrumBalance get balance => _balance.value.copy();

  bool supports(BitcoinAddressType type) => supportedTypes.contains(type);

  @override
  String toString() {
    final b = _balance.value;
    return "ElectrumAccount(index: $index, label: $label, "
        'types: ${supportedTypes.map((t) => t.value).join('/')}, '
        "balance: c=${b.confirmed} u=${b.unconfirmed} f=${b.frozen})";
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
