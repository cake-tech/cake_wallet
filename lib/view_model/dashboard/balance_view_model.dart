import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/dashboard/wallet_balance.dart';
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
      @required this.fiatConvertationStore})
      : isReversing = false;

  final AppStore appStore;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConvertationStore;

  bool get canReverse =>
      (appStore.wallet.balance.availableModes as List).length > 1;

  @observable
  bool isReversing;

  @computed
  double get price => fiatConvertationStore.prices[appStore.wallet.currency];

  @computed
  BalanceDisplayMode get savedDisplayMode => settingsStore.balanceDisplayMode;

  @computed
  BalanceDisplayMode get displayMode => isReversing
      ? (savedDisplayMode == BalanceDisplayMode.availableBalance
          ? BalanceDisplayMode.fullBalance
          : BalanceDisplayMode.availableBalance)
      : savedDisplayMode;

  @computed
  String get cryptoBalance {
    final walletBalance = _walletBalance;
    var balance = '---';

    if (displayMode == BalanceDisplayMode.availableBalance) {
      balance = walletBalance.unlockedBalance ?? '0.0';
    }

    if (displayMode == BalanceDisplayMode.fullBalance) {
      balance = walletBalance.totalBalance ?? '0.0';
    }

    return balance;
  }

  @computed
  String get fiatBalance {
    final walletBalance = _walletBalance;
    final fiatCurrency = settingsStore.fiatCurrency;
    var balance = '---';

    final totalBalance =
        _getFiatBalance(price: price, cryptoAmount: walletBalance.totalBalance);

    final unlockedBalance = _getFiatBalance(
        price: price, cryptoAmount: walletBalance.unlockedBalance);

    if (displayMode == BalanceDisplayMode.availableBalance) {
      balance = fiatCurrency.toString() + ' ' + unlockedBalance ?? '0.00';
    }

    if (displayMode == BalanceDisplayMode.fullBalance) {
      balance = fiatCurrency.toString() + ' ' + totalBalance ?? '0.00';
    }

    return balance;
  }

  @computed
  WalletBalance get _walletBalance {
    final _wallet = appStore.wallet;

    if (_wallet is MoneroWallet) {
      return WalletBalance(
          unlockedBalance: _wallet.balance.formattedUnlockedBalance,
          totalBalance: _wallet.balance.formattedFullBalance);
    }

    if (_wallet is BitcoinWallet) {
      return WalletBalance(
          unlockedBalance: _wallet.balance.availableBalanceFormatted,
          totalBalance: _wallet.balance.totalFormatted);
    }

    return null;
  }

  @computed
  CryptoCurrency get currency => appStore.wallet.currency;

  String _getFiatBalance({double price, String cryptoAmount}) {
    if (cryptoAmount == null) {
      return '0.00';
    }

    return calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
  }
}
