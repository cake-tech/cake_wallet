import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/monero/monero_balance.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/calculate_fiat_amount.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';

part 'balance_store.g.dart';

class BalanceStore = BalanceStoreBase with _$BalanceStore;

abstract class BalanceStoreBase with Store {
  @observable
  String fullBalance;

  @observable
  String unlockedBalance;

  @computed
  String get fiatFullBalance {
    if (fullBalance == null) {
      return '0.00';
    }

    final symbol = PriceStoreBase.generateSymbolForPair(
        fiat: _settingsStore.fiatCurrency, crypto: CryptoCurrency.xmr);
    final price = _priceStore.prices[symbol];
    return calculateFiatAmount(price: price, cryptoAmount: fullBalance);
  }

  @computed
  String get fiatUnlockedBalance {
    if (unlockedBalance == null) {
      return '0.00';
    }

    final symbol = PriceStoreBase.generateSymbolForPair(
        fiat: _settingsStore.fiatCurrency, crypto: CryptoCurrency.xmr);
    final price = _priceStore.prices[symbol];
    return calculateFiatAmount(price: price, cryptoAmount: unlockedBalance);
  }

  @observable
  bool isReversing;

  WalletService _walletService;
  StreamSubscription<Wallet> _onWalletChangeSubscription;
  StreamSubscription<Balance> _onBalanceChangeSubscription;
  SettingsStore _settingsStore;
  PriceStore _priceStore;

  BalanceStoreBase(
      {String fullBalance = '0.0',
      String unlockedBalance = '0.0',
      @required WalletService walletService,
      @required SettingsStore settingsStore,
      @required PriceStore priceStore}) {
    fullBalance = fullBalance;
    unlockedBalance = unlockedBalance;
    isReversing = false;
    _walletService = walletService;
    _settingsStore = settingsStore;
    _priceStore = priceStore;

    if (_walletService.currentWallet != null) {
      _onWalletChanged(_walletService.currentWallet);
    }

    _onWalletChangeSubscription = _walletService.onWalletChange
        .listen((wallet) => _onWalletChanged(wallet));
  }

  @override
  void dispose() {
    _onWalletChangeSubscription.cancel();

    if (_onBalanceChangeSubscription != null) {
      _onBalanceChangeSubscription.cancel();
    }

    super.dispose();
  }

  Future _onBalanceChange(Balance balance) async {
    final _balance = balance as MoneroBalance;

    if (this.fullBalance != _balance.fullBalance) {
      this.fullBalance = _balance.fullBalance;
    }

    if (this.unlockedBalance != _balance.unlockedBalance) {
      this.unlockedBalance = _balance.unlockedBalance;
    }
  }

  Future _onWalletChanged(Wallet wallet) async {
    if (_onBalanceChangeSubscription != null) {
      _onBalanceChangeSubscription.cancel();
    }

    _onBalanceChangeSubscription = _walletService.onBalanceChange
        .listen((balance) async => await _onBalanceChange(balance));

    await _updateBalances(wallet);
  }

  Future _updateBalances(Wallet wallet) async {
    if (wallet == null) {
      return;
    }

    fullBalance = await _walletService.getFullBalance();
    unlockedBalance = await _walletService.getUnlockedBalance();
  }
}
