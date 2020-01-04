import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/fetch_price.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';

bool _startedUpdatingPrice = false;

_updatePrice(Map args) async =>
    await fetchPriceFor(fiat: args['fiat'], crypto: args['crypto']);

updatePrice(Map args) async => compute(_updatePrice, args);

startUpdatingPrice({SettingsStore settingsStore, PriceStore priceStore}) async {
  if (_startedUpdatingPrice) {
    return;
  }

  const currentCrypto = CryptoCurrency.xmr;
  _startedUpdatingPrice = true;

  final price = await updatePrice(
      {'fiat': settingsStore.fiatCurrency, 'crypto': currentCrypto});
  priceStore.changePriceForPair(
      fiat: settingsStore.fiatCurrency, crypto: currentCrypto, price: price);

  Timer.periodic(Duration(seconds: 30), (_) async {
    final price = await updatePrice(
        {'fiat': settingsStore.fiatCurrency, 'crypto': currentCrypto});
    priceStore.changePriceForPair(
        fiat: settingsStore.fiatCurrency, crypto: currentCrypto, price: price);
  });
}
