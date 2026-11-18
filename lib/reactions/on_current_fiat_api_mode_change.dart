import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/app_store.dart';

ReactionDisposer? _onCurrentFiatCurrencyChangeDisposer;

void startCurrentFiatApiModeChangeReaction(
    AppStore appStore, SettingsStore settingsStore, FiatConversionStore fiatConversionStore) {
  _onCurrentFiatCurrencyChangeDisposer?.reaction.dispose();
  _onCurrentFiatCurrencyChangeDisposer =
      reaction((_) => settingsStore.fiatApiMode, (FiatApiMode fiatApiMode) async {
    if (appStore.wallet == null || fiatApiMode == FiatApiMode.disabled) {
      return;
    }

    await fiatConversionStore.fetchPrice(appStore.wallet!.currency, force: true);
  });
}
