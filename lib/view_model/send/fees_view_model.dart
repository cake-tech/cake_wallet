import 'package:cake_wallet/bitcoin_cash/bitcoin_cash.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/digibyte/digibyte.dart';
import 'package:cake_wallet/dogecoin/dogecoin.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:collection/collection.dart';

part 'fees_view_model.g.dart';

class FeesViewModel = FeesViewModelBase with _$FeesViewModel;

abstract class FeesViewModelBase extends WalletChangeListenerViewModel with Store {
  FeesViewModelBase(
    AppStore appStore,
    this.balanceViewModel,
  )   : _settingsStore = appStore.settingsStore,
        super(appStore: appStore) {
    if (wallet.type == WalletType.bitcoin &&
        _settingsStore.priority[wallet.type] == bitcoinTransactionPriorityCustom) {
      setTransactionPriority(bitcoinTransactionPriorityMedium);
    }
    final priority = _settingsStore.priority[wallet.type];
    final priorities = priorityForWalletType(wallet.type);
    if (!priorityForWalletType(wallet.type).contains(priority) && priorities.isNotEmpty) {
      _settingsStore.priority[wallet.type] = priorities.first;
    }
  }

  @computed
  WalletType get walletType => wallet.type;
  CryptoCurrency get currency => wallet.currency;
  FiatCurrency get fiat => _settingsStore.fiatCurrency;
  bool get isFiatDisabled => balanceViewModel.isFiatDisabled;

  final BalanceViewModel balanceViewModel;

  TransactionPriority get transactionPriority {
    final priority = _settingsStore.priority[wallet.type];

    if (priority == null) {
      throw Exception('Unexpected type ${wallet.type}');
    }

    return priority;
  }

  int? getCustomPriorityIndex(List<TransactionPriority> priorities) {
    if (wallet.type == WalletType.bitcoin) {
      final customItem = priorities
          .firstWhereOrNull((element) => element == bitcoin!.getBitcoinTransactionPriorityCustom());

      return customItem != null ? priorities.indexOf(customItem) : null;
    }
    return null;
  }

  int? get maxCustomFeeRate {
    if (wallet.type == WalletType.bitcoin) {
      return bitcoin!.getMaxCustomFeeRate(wallet);
    }
    return null;
  }

  bool get isLowFee {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.wownero:
      case WalletType.haven:
      case WalletType.zano:
        return transactionPriority == monero!.getMoneroTransactionPrioritySlow();
      case WalletType.bitcoin:
        return transactionPriority == bitcoin!.getBitcoinTransactionPrioritySlow();
      case WalletType.litecoin:
        return transactionPriority == bitcoin!.getLitecoinTransactionPrioritySlow();
      case WalletType.ethereum:
        return transactionPriority == ethereum!.getEthereumTransactionPrioritySlow();
      case WalletType.bitcoinCash:
        return transactionPriority == bitcoinCash!.getBitcoinCashTransactionPrioritySlow();
      case WalletType.polygon:
        return transactionPriority == polygon!.getPolygonTransactionPrioritySlow();
      case WalletType.decred:
        return transactionPriority == decred!.getDecredTransactionPrioritySlow();
      case WalletType.dogecoin:
        return transactionPriority == dogecoin!.getDogeCoinTransactionPrioritySlow();
      case WalletType.digibyte:
        return transactionPriority == digibyte!.getDigibyteTransactionPrioritySlow();
      case WalletType.none:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.solana:
      case WalletType.tron:
        return false;
    }
  }

  @computed
  int get customBitcoinFeeRate => _settingsStore.customBitcoinFeeRate;

  void set customBitcoinFeeRate(int value) => _settingsStore.customBitcoinFeeRate = value;

  @computed
  bool get hasFees => wallet.type != WalletType.nano && wallet.type != WalletType.banano;

  @computed
  bool get hasFeesPriority =>
      wallet.type != WalletType.nano &&
      wallet.type != WalletType.banano &&
      wallet.type != WalletType.solana &&
      wallet.type != WalletType.tron;

  @computed
  bool get isElectrumWallet =>
      wallet.type == WalletType.bitcoin ||
      wallet.type == WalletType.litecoin ||
      wallet.type == WalletType.bitcoinCash ||
      wallet.type == WalletType.dogecoin ||
      wallet.type == WalletType.digibyte;

  String? get walletCurrencyName => wallet.currency.fullName?.toLowerCase() ?? wallet.currency.name;

  @computed
  FiatCurrency get fiatCurrency => _settingsStore.fiatCurrency;

  final SettingsStore _settingsStore;

  @action
  void setTransactionPriority(TransactionPriority priority) =>
      _settingsStore.priority[wallet.type] = priority;

  bool showAlertForCustomFeeRate() {
    if (wallet.type != WalletType.bitcoin || isLowFee) {
      return false;
    }

    if (transactionPriority != bitcoinTransactionPriorityCustom) {
      return false;
    }

    final mediumRate = bitcoin!.getFeeRate(wallet, bitcoinTransactionPriorityMedium);
    return customBitcoinFeeRate < mediumRate;
  }

  String displayFeeRate(dynamic priority, int? customValue) {
    final _priority = priority as TransactionPriority;

    if (wallet.type == WalletType.bitcoin) {
      final rate = bitcoin!.getFeeRate(wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate, customRate: customValue);
    }

    if (isElectrumWallet) {
      final rate = bitcoin!.getFeeRate(wallet, _priority);
      return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate);
    }

    return priority.toString();
  }

  TransactionPriority get bitcoinTransactionPriorityCustom =>
      bitcoin!.getBitcoinTransactionPriorityCustom();

  TransactionPriority get bitcoinTransactionPriorityMedium =>
      bitcoin!.getBitcoinTransactionPriorityMedium();

  @action
  void setDefaultTransactionPriority() {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.wownero:
      case WalletType.zano:
        _settingsStore.priority[wallet.type] = monero!.getMoneroTransactionPriorityAutomatic();
        break;
      case WalletType.bitcoin:
        _settingsStore.priority[wallet.type] = bitcoin!.getBitcoinTransactionPriorityMedium();
        break;
      case WalletType.litecoin:
        _settingsStore.priority[wallet.type] = bitcoin!.getLitecoinTransactionPriorityMedium();
        break;
      case WalletType.ethereum:
        _settingsStore.priority[wallet.type] = ethereum!.getDefaultTransactionPriority();
        break;
      case WalletType.bitcoinCash:
        _settingsStore.priority[wallet.type] = bitcoinCash!.getDefaultTransactionPriority();
        break;
      case WalletType.dogecoin:
        _settingsStore.priority[wallet.type] = dogecoin!.getDefaultTransactionPriority();
        break;
      case WalletType.digibyte:
        _settingsStore.priority[wallet.type] = digibyte!.getDefaultTransactionPriority();
        break;
      case WalletType.polygon:
        _settingsStore.priority[wallet.type] = polygon!.getDefaultTransactionPriority();
        break;
      default:
        break;
    }
  }
}
