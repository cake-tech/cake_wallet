import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/calculate_fiat_amount.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/view_model/dashboard/wallet_balance.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';

part 'balance_view_model.g.dart';

class BalanceViewModel = BalanceViewModelBase with _$BalanceViewModel;

abstract class BalanceViewModelBase with Store {
  BalanceViewModelBase({
    @required this.wallet,
    @required this.settingsStore,
    @required this.priceStore
  });

  final WalletBase wallet;
  final SettingsStore settingsStore;
  final PriceStore priceStore;

  WalletBalance _getWalletBalance() {
    final _wallet = wallet;

    if (_wallet is MoneroWallet) {
      return  WalletBalance(
          unlockedBalance: _wallet.balance.formattedUnlockedBalance,
          totalBalance: _wallet.balance.formattedFullBalance);
    }

    if (_wallet is BitcoinWallet) {
      return WalletBalance(
          unlockedBalance: _wallet.balance.confirmedFormatted,
          totalBalance: _wallet.balance.unconfirmedFormatted);
    }
  }

  String _getFiatBalance({double price, String cryptoAmount}) {
    if (cryptoAmount == null) {
      return '0.00';
    }

    return calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
  }

  @computed
  double get price {
    String symbol;
    final _wallet = wallet;

    if (_wallet is MoneroWallet) {
      symbol = PriceStoreBase.generateSymbolForPair(
          fiat: settingsStore.fiatCurrency, crypto: CryptoCurrency.xmr);
    }

    if (_wallet is BitcoinWallet) {
      symbol = PriceStoreBase.generateSymbolForPair(
          fiat: settingsStore.fiatCurrency, crypto: CryptoCurrency.btc);
    }

    return priceStore.prices[symbol];
  }

  @computed
  String get cryptoBalance {
    final walletBalance = _getWalletBalance();
    final displayMode = settingsStore.balanceDisplayMode;
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
    final walletBalance = _getWalletBalance();
    final displayMode = settingsStore.balanceDisplayMode;
    final fiatCurrency = settingsStore.fiatCurrency;
    var balance = '---';

    final totalBalance = _getFiatBalance(
        price: price,
        cryptoAmount: walletBalance.totalBalance
    );

    final unlockedBalance = _getFiatBalance(
        price: price,
        cryptoAmount: walletBalance.unlockedBalance
    );

    if (displayMode == BalanceDisplayMode.availableBalance) {
      balance = fiatCurrency.toString() + ' ' + unlockedBalance ?? '0.00';
    }

    if (displayMode == BalanceDisplayMode.fullBalance) {
      balance = fiatCurrency.toString() + ' ' + totalBalance ?? '0.00';
    }

    return balance;
  }

}