import 'dart:async';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fetch_price.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';

bool _startedUpdatingPrice = false;

Future<double> _updatePrice(Map args) async => await fetchPriceFor(
    fiat: args['fiat'] as FiatCurrency,
    crypto: args['crypto'] as CryptoCurrency);

Future<double> updatePrice(Map args) async => compute(_updatePrice, args);

Future<void> startUpdatingPrice(
    {SettingsStore settingsStore, PriceStore priceStore, WalletStore walletStore}) async {
  if (_startedUpdatingPrice) {
    return;
  }

  _startedUpdatingPrice = true;

  final price = await updatePrice(
      <String, dynamic>{'fiat': settingsStore.fiatCurrency, 'crypto': walletStore.type});
  priceStore.changePriceForPair(
      fiat: settingsStore.fiatCurrency, crypto: walletStore.type, price: price);

  Timer.periodic(Duration(seconds: 30), (_) async {
    final price = await updatePrice(
        <String, dynamic>{'fiat': settingsStore.fiatCurrency, 'crypto': walletStore.type});
    priceStore.changePriceForPair(
        fiat: settingsStore.fiatCurrency, crypto: walletStore.type, price: price);
  });
}
