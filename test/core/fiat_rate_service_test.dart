import "dart:async";

import "package:cake_wallet/core/fiat_rate_service.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

class _FakeSettingsStore extends Fake implements SettingsStore {
  _FakeSettingsStore({
    FiatCurrency fiat = FiatCurrency.usd,
    FiatApiMode mode = FiatApiMode.enabled,
  })  : _fiat = Observable<FiatCurrency>(fiat),
        _mode = Observable<FiatApiMode>(mode);

  final Observable<FiatCurrency> _fiat;
  final Observable<FiatApiMode> _mode;

  @override
  FiatCurrency get fiatCurrency => _fiat.value;

  @override
  set fiatCurrency(FiatCurrency next) {
    runInAction(() => _fiat.value = next);
  }

  @override
  FiatApiMode get fiatApiMode => _mode.value;

  @override
  set fiatApiMode(FiatApiMode next) {
    runInAction(() => _mode.value = next);
  }
}

FiatRateService _build(
  FiatConversionStore prices,
  _FakeSettingsStore settings,
) =>
    FiatRateService(fiatConversionStore: prices, settingsStore: settings);

void main() {
  late FiatConversionStore prices;
  late _FakeSettingsStore settings;

  setUp(() {
    prices = FiatConversionStore();
    settings = _FakeSettingsStore();
  });

  group("defaultFiat", () {
    test("reads current settings fiat", () {
      settings = _FakeSettingsStore(fiat: FiatCurrency.eur);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(service.defaultFiat, FiatCurrency.eur);
    });

    test("reflects mutations to the settings", () {
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(service.defaultFiat, FiatCurrency.usd);
      settings.fiatCurrency = FiatCurrency.eur;
      expect(service.defaultFiat, FiatCurrency.eur);
    });
  });

  group("rateFor", () {
    test("returns live price when fiat is the default", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(service.rateFor(CryptoCurrency.btc, FiatCurrency.usd), 30000);
    });

    test("returns null when fiat is default and no live price exists", () {
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(service.rateFor(CryptoCurrency.btc, FiatCurrency.usd), isNull);
    });

    test("returns null when fiat is not default and no custom rate cached", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(service.rateFor(CryptoCurrency.btc, FiatCurrency.eur), isNull);
    });

    test("live price is per-crypto — unknown crypto returns null", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(service.rateFor(CryptoCurrency.eth, FiatCurrency.usd), isNull);
    });
  });

  group("convertToFiat", () {
    test("returns null when fiat is disabled", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      settings.fiatApiMode = FiatApiMode.disabled;
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertToFiat(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when amount is not a crypto currency", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertToFiat(Money.parse("1", FiatCurrency.usd), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when there is no rate", () {
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertToFiat(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when the rate is zero or negative", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 0);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertToFiat(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );

      runInAction(() => prices.prices[CryptoCurrency.btc] = -5);
      expect(
        service.convertToFiat(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("computes fiat value with rate", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      final result = service.convertToFiat(
        Money.parse("0.5", CryptoCurrency.btc),
        FiatCurrency.usd,
      );
      expect(result, isNotNull);
      expect(result!.toDouble(), 15000);
      expect(result.currency, FiatCurrency.usd);
    });

    test("respects target fiat decimals", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      final result = service.convertToFiat(
        Money.parse("0.00033333", CryptoCurrency.btc),
        FiatCurrency.usd,
      );
      expect(result, isNotNull);
      // 30000 * 0.00033333 = ~9.9999. Rounded to USD decimals (2) → "10.00",
      // rendered without trailing zeros as "10".
      expect(
        result!.toStringWithPrecision(fractionalDigits: 2, trimZeros: false),
        "10.00",
      );
    });
  });

  group("convertFromFiat", () {
    test("returns null when fiat is disabled", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      settings.fiatApiMode = FiatApiMode.disabled;
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertFromFiat(Money.parse("100", FiatCurrency.usd), CryptoCurrency.btc),
        isNull,
      );
    });

    test("returns null when amount is not a fiat currency", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertFromFiat(Money.parse("1", CryptoCurrency.btc), CryptoCurrency.btc),
        isNull,
      );
    });

    test("returns null when there is no rate", () {
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertFromFiat(Money.parse("100", FiatCurrency.usd), CryptoCurrency.btc),
        isNull,
      );
    });

    test("returns null when the rate is zero or negative", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 0);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      expect(
        service.convertFromFiat(Money.parse("100", FiatCurrency.usd), CryptoCurrency.btc),
        isNull,
      );
    });

    test("computes crypto value with rate", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      final result = service.convertFromFiat(
        Money.parse("15000", FiatCurrency.usd),
        CryptoCurrency.btc,
      );
      expect(result, isNotNull);
      expect(result!.currency, CryptoCurrency.btc);
      expect(result.toDouble(), closeTo(0.5, 1e-8));
    });

    test("round-trips convertToFiat / convertFromFiat within currency decimals", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 25000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      final original = Money.parse("0.5", CryptoCurrency.btc);
      final asFiat = service.convertToFiat(original, FiatCurrency.usd);
      expect(asFiat, isNotNull);
      final back = service.convertFromFiat(asFiat!, CryptoCurrency.btc);
      expect(back, isNotNull);
      expect(back!.toDouble(), closeTo(original.toDouble(), 1e-6));
    });
  });

  group("ensureRateFor", () {
    test("returns immediately when a live rate is already cached", () async {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      // Timeout means the method didn't await anything network-ish.
      await service
          .ensureRateFor(CryptoCurrency.btc, FiatCurrency.usd)
          .timeout(const Duration(milliseconds: 50));
    });

    test("returns immediately for the default fiat, even without a cached price", () {
      final service = _build(prices, settings);
      addTearDown(service.dispose);

      final future = service.ensureRateFor(CryptoCurrency.btc, FiatCurrency.usd);
      expect(future, isA<Future<void>>());
    });
  });

  group("rateChanges", () {
    test("is a broadcast stream", () {
      final service = _build(prices, settings);
      addTearDown(service.dispose);
      expect(service.rateChanges.isBroadcast, isTrue);
    });

    test("emits when the price map is mutated", () async {
      final service = _build(prices, settings);
      addTearDown(service.dispose);
      final events = <void>[];
      final sub = service.rateChanges.listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);
      events.clear();

      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      await Future<void>.delayed(Duration.zero);

      expect(events, isNotEmpty);
    });

    test("emits when settings.fiatCurrency changes", () async {
      final service = _build(prices, settings);
      addTearDown(service.dispose);
      final events = <void>[];
      final sub = service.rateChanges.listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);
      events.clear();

      settings.fiatCurrency = FiatCurrency.eur;
      await Future<void>.delayed(Duration.zero);

      expect(events, isNotEmpty);
    });
  });

  group("dispose", () {
    test("closes the rateChanges stream", () async {
      final service = _build(prices, settings);
      final done = Completer<void>();
      final sub = service.rateChanges.listen((_) {}, onDone: done.complete);
      addTearDown(sub.cancel);

      await service.dispose();
      await done.future;
    });

    test("subsequent MobX changes do not push events after dispose", () async {
      final service = _build(prices, settings);
      final events = <void>[];
      final sub = service.rateChanges.listen(events.add);
      addTearDown(sub.cancel);

      await service.dispose();
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      settings.fiatCurrency = FiatCurrency.eur;
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });
}
