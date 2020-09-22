import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

ReactionDisposer _onCurrentFiatCurrencyChangeDisposer;

void startCurrentFiatChangeReaction(AppStore appStore, SettingsStore settingsStore) {
  _onCurrentFiatCurrencyChangeDisposer?.reaction?.dispose();
  _onCurrentFiatCurrencyChangeDisposer = reaction(
          (_) => settingsStore.fiatCurrency, (FiatCurrency fiatCurrency) async {
    final cryptoCurrency = appStore.wallet.currency;
    // final price = await fiatConvertationService.getPrice(
    //     crypto: cryptoCurrency, fiat: fiatCurrency);
    //
    // fiatConvertationStore.setPrice(price);
  });
}