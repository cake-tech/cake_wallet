import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;

class _FakeSettingsStore extends Fake implements SettingsStore {
  final _fiatApiMode = Observable(FiatApiMode.enabled);
  final _fiatCurrency = Observable(FiatCurrency.usd);

  @override
  FiatCurrency get fiatCurrency => _fiatCurrency.value;

  @override
  set fiatCurrency(FiatCurrency currency) => runInAction(() => _fiatCurrency.value = currency);

  @override
  FiatApiMode get fiatApiMode => _fiatApiMode.value;

  @override
  set fiatApiMode(FiatApiMode mode) => runInAction(() => _fiatApiMode.value = mode);
}

void main() {
  late _FakeSettingsStore settingsStore;
  late FiatConversionStore fiatConversionStore;

  setUp(() {
    settingsStore = _FakeSettingsStore();
    fiatConversionStore = FiatConversionStore();
  });

  FiatRateCubit ethRate() {
    final cubit = FiatRateCubit(
      currency: CryptoCurrency.eth,
      settingsStore: settingsStore,
      fiatConversionStore: fiatConversionStore,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test("keeps the last price when a refresh fails", () {
    fiatConversionStore.prices[CryptoCurrency.eth] = 2500.0;
    final cubit = ethRate();

    // FiatConversionService.fetchPrice returns 0 when the request fails.
    runInAction(() => fiatConversionStore.prices[CryptoCurrency.eth] = 0.0);

    expect(
      cubit.state!.convert(Money.parse("1", CryptoCurrency.eth)),
      Money.parse("2500", FiatCurrency.usd),
    );
  });

  test("has no rate once fiat prices are turned off, even after a failed refresh", () {
    fiatConversionStore.prices[CryptoCurrency.eth] = 2500.0;
    final cubit = ethRate();
    runInAction(() => fiatConversionStore.prices[CryptoCurrency.eth] = 0.0);

    settingsStore.fiatApiMode = FiatApiMode.disabled;

    expect(cubit.state, isNull);
  });

  test("drops the retained quote when fiat changes and accepts the new price", () async {
    fiatConversionStore.prices[CryptoCurrency.eth] = 2500.0;
    final cubit = ethRate();
    runInAction(() => fiatConversionStore.prices[CryptoCurrency.eth] = 0.0);

    settingsStore.fiatCurrency = FiatCurrency.eur;

    expect(cubit.state, isNull);

    final next = cubit.stream.first;
    runInAction(() => fiatConversionStore.prices[CryptoCurrency.eth] = 2300.0);

    expect(
      (await next)!.convert(Money.parse("1", CryptoCurrency.eth)),
      Money.parse("2300", FiatCurrency.eur),
    );
  });

  test("converts at the exact price, not one rounded to cents", () {
    settingsStore.fiatCurrency = FiatCurrency.eur;
    fiatConversionStore.prices[CryptoCurrency.usdc] = 0.8634;
    final cubit = FiatRateCubit(
      currency: CryptoCurrency.usdc,
      settingsStore: settingsStore,
      fiatConversionStore: fiatConversionStore,
    );
    addTearDown(cubit.close);

    expect(
      cubit.state!.convert(Money.parse("100", CryptoCurrency.usdc)),
      Money.parse("86.34", FiatCurrency.eur),
    );
  });
}
