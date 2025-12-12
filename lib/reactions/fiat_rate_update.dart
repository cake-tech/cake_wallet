import 'dart:async';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

Timer? _timer;

Future<void> startFiatRateUpdate(
    AppStore appStore, SettingsStore settingsStore, FiatConversionStore fiatConversionStore) async {
  if (_timer != null) {
    return;
  }

  final _updateFiat = (_) async {
    try {
      if (appStore.wallet == null || settingsStore.fiatApiMode == FiatApiMode.disabled) {
        return;
      }

      fiatConversionStore.prices[appStore.wallet!.currency] =
          await FiatConversionService.fetchPrice(
              crypto: appStore.wallet!.currency,
              fiat: settingsStore.fiatCurrency,
              torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly);

      Iterable<CryptoCurrency>? currencies;
      if (isEVMCompatibleChain(appStore.wallet!.type)) {
        currencies =
            evm!.getERC20Currencies(appStore.wallet!).where((element) => element.enabled);
      }

      if (appStore.wallet!.type == WalletType.solana) {
        currencies =
            solana!.getSPLTokenCurrencies(appStore.wallet!).where((element) => element.enabled);
      }

      if (appStore.wallet!.type == WalletType.tron) {
        currencies =
            tron!.getTronTokenCurrencies(appStore.wallet!).where((element) => element.enabled);
      }

      if (currencies != null) {
        for (final currency in currencies) {
          // skip potential scams:
          if (currency.isPotentialScam) {
            continue;
          }
          () async {
            fiatConversionStore.prices[currency] = await FiatConversionService.fetchPrice(
                crypto: currency,
                fiat: settingsStore.fiatCurrency,
                torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly);
          }.call();
        }
      }
    } catch (e) {
      printV(e);
    }
  };

  _timer = Timer.periodic(Duration(seconds: 30), _updateFiat);
  // also run immediately:
  _updateFiat(null);

  // setup autorun to listen to changes in fiatApiMode
  autorun((_) {
    // restart the timer if fiatApiMode was re-enabled
    if (settingsStore.fiatApiMode != FiatApiMode.disabled) {
      _timer = Timer.periodic(Duration(seconds: 30), _updateFiat);
      _updateFiat(null);
    } else {
      _timer?.cancel();
    }
  });
}
