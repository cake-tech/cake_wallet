import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';

part 'balance_view_model.g.dart';

class BalanceViewModel = BalanceViewModelBase with _$BalanceViewModel;

abstract class BalanceViewModelBase with Store {
  BalanceViewModelBase(
      {@required this.appStore,
      @required this.settingsStore,
      @required this.fiatConvertationStore}) {
    isReversing = false;
    wallet ??= appStore.wallet;
    balance = wallet.balance;

    reaction((_) => appStore.wallet, _onWalletChange);

    _onCurrentWalletChangeReaction =
        reaction<void>((_) => wallet.balance, (dynamic balance) {
      if (balance is Balance) {
        this.balance = balance;
      }
    });
  }

  final AppStore appStore;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConvertationStore;

  bool get canReverse => false;

  @observable
  bool isReversing;

  @observable
  Balance balance;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
      wallet;

  @computed
  double get price => fiatConvertationStore.prices[appStore.wallet.currency];

  @computed
  BalanceDisplayMode get savedDisplayMode => settingsStore.balanceDisplayMode;

  @computed
  BalanceDisplayMode get displayMode => isReversing
      ? savedDisplayMode == BalanceDisplayMode.hiddenBalance
          ? BalanceDisplayMode.displayableBalance
          : savedDisplayMode
      : savedDisplayMode;

  @computed
  String get availableBalanceLabel {
    if (wallet.type == WalletType.monero) {
      return S.current.xmr_available_balance;
    }

    return S.current.confirmed;
  }

  @computed
  String get additionalBalanceLabel {
    if (wallet.type == WalletType.monero) {
      return S.current.xmr_full_balance;
    }

    return S.current.unconfirmed;
  }

  @computed
  String get availableBalance {
    final walletBalance = _walletBalance;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return walletBalance.formattedAvailableBalance;
  }

  @computed
  String get additionalBalance {
    final walletBalance = _walletBalance;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return walletBalance.formattedAdditionalBalance;
  }

  @computed
  String get availableFiatBalance {
    final walletBalance = _walletBalance;
    final fiatCurrency = settingsStore.fiatCurrency;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return fiatCurrency.toString() +
        ' ' +
        _getFiatBalance(
            price: price,
            cryptoAmount: walletBalance.formattedAvailableBalance);
  }

  @computed
  String get additionalFiatBalance {
    final walletBalance = _walletBalance;
    final fiatCurrency = settingsStore.fiatCurrency;

    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }

    return fiatCurrency.toString() +
        ' ' +
        _getFiatBalance(
            price: price,
            cryptoAmount: walletBalance.formattedAdditionalBalance);
  }

  @computed
  Balance get _walletBalance => wallet.balance;

  @computed
  CryptoCurrency get currency => appStore.wallet.currency;

  ReactionDisposer _onCurrentWalletChangeReaction;

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet) {
    this.wallet = wallet;
    balance = wallet.balance;
    _onCurrentWalletChangeReaction?.reaction?.dispose();
    _onCurrentWalletChangeReaction = reaction<Balance>(
        (_) => wallet.balance, (Balance balance) => this.balance = balance);
  }

  String _getFiatBalance({double price, String cryptoAmount}) {
    if (cryptoAmount == null) {
      return '0.00';
    }

    return calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
  }
}
