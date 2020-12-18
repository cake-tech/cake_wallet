import 'dart:async';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';

Timer _timer;

Future<void> startFiatRateUpdate(AppStore appStore, SettingsStore settingsStore,
    FiatConversionStore fiatConversionStore) async {
  if (_timer != null) {
    return;
  }

  fiatConversionStore.prices[appStore.wallet.currency] =
      await FiatConversionService.fetchPrice(
          appStore.wallet.currency, settingsStore.fiatCurrency);

  _timer = Timer.periodic(
      Duration(seconds: 30),
      (_) async => fiatConversionStore.prices[appStore.wallet.currency] =
          await FiatConversionService.fetchPrice(
              appStore.wallet.currency, settingsStore.fiatCurrency));
}
