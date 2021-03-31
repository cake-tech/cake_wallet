import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
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

    _reaction = reaction((_) => appStore.wallet, _onWalletChange);

    final _wallet = wallet;

    if (_wallet is MoneroWallet) {
      balance = _wallet.balance;
    }

    if (_wallet is BitcoinWallet) {
      balance = _wallet.balance;
    }

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
  WalletBase<Balance> wallet;

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
  ReactionDisposer _reaction;

  @action
  void _onWalletChange(WalletBase<Balance> wallet) {
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
