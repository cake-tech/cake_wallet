import 'dart:async';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/update_haven_rate.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';

Timer? _timer;

Future<void> startFiatRateUpdate(
    AppStore appStore, SettingsStore settingsStore, FiatConversionStore fiatConversionStore) async {
  if (_timer != null) {
    return;
  }

  _timer = Timer.periodic(Duration(seconds: 30), (_) async {
    try {
      if (appStore.wallet == null || settingsStore.fiatApiMode == FiatApiMode.disabled) {
        return;
      }

      if (appStore.wallet!.type == WalletType.haven) {
        await updateHavenRate(fiatConversionStore);
      } else {
        fiatConversionStore.prices[appStore.wallet!.currency] =
            await FiatConversionService.fetchPrice(
                crypto: appStore.wallet!.currency,
                fiat: settingsStore.fiatCurrency,
                torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly);
      }
    } catch (e) {
      print(e);
    }
  });
}
