import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

ReactionDisposer _onCurrentFiatCurrencyChangeDisposer;

void startCurrentFiatChangeReaction(AppStore appStore, SettingsStore settingsStore, FiatConversionStore fiatConversionStore) {
  _onCurrentFiatCurrencyChangeDisposer?.reaction?.dispose();
  _onCurrentFiatCurrencyChangeDisposer = reaction(
          (_) => settingsStore.fiatCurrency, (FiatCurrency fiatCurrency) async {
    final cryptoCurrency = appStore.wallet.currency;
    fiatConversionStore.price = await FiatConversionService.fetchPrice(
        cryptoCurrency, fiatCurrency);
  });
}