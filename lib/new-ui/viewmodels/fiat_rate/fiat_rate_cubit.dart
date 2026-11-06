import "package:bloc/bloc.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:mobx/mobx.dart" show ReactionDisposer, reaction;

// TODO(lapatric): move _rate into FiatConversionStore once the swap refactor (cw-1556) lands
class FiatRateCubit extends Cubit<ExchangeRate?> {
  FiatRateCubit({
    required CryptoCurrency currency,
    required SettingsStore settingsStore,
    required FiatConversionStore fiatConversionStore,
  }) : super(_rate(currency, settingsStore, fiatConversionStore)) {
    _disposer = reaction(
      (_) => (
        disabled: settingsStore.fiatApiMode == FiatApiMode.disabled,
        fiatCurrency: settingsStore.fiatCurrency,
        rate: _rate(currency, settingsStore, fiatConversionStore),
      ),
      (next) {
        if (next.rate != null || next.disabled || state?.quote.currency != next.fiatCurrency) {
          emit(next.rate);
        }
      },
      equals: (a, b) =>
          a?.disabled == b?.disabled &&
          a?.fiatCurrency == b?.fiatCurrency &&
          a?.rate?.quote == b?.rate?.quote,
    );
  }

  late final ReactionDisposer _disposer;

  static ExchangeRate? _rate(
    CryptoCurrency currency,
    SettingsStore settingsStore,
    FiatConversionStore fiatConversionStore,
  ) {
    final price = fiatConversionStore.prices[currency];
    if (settingsStore.fiatApiMode == FiatApiMode.disabled || price == null || price <= 0) {
      return null;
    }

    return ExchangeRate(
      base: currency,
      quote: Money.parse(_plainDecimal(price), settingsStore.fiatCurrency, strictParsing: false),
    );
  }

  static String _plainDecimal(double value) {
    final source = value.toString();
    return source.contains("e") ? value.toStringAsFixed(20) : source;
  }

  @override
  Future<void> close() {
    _disposer();
    return super.close();
  }
}
