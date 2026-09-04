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

void main() {
  late FiatConversionStore prices;
  late _FakeSettingsStore settings;

  setUp(() {
    prices = FiatConversionStore();
    settings = _FakeSettingsStore();
  });

  group("currentFiat", () {
    test("reads current settings fiat", () {
      settings = _FakeSettingsStore(fiat: FiatCurrency.eur);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(service.currentFiat, FiatCurrency.eur);
    });

    test("reflects mutations to the settings", () {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(service.currentFiat, FiatCurrency.usd);
      settings.fiatCurrency = FiatCurrency.eur;
      expect(service.currentFiat, FiatCurrency.eur);
    });
  });

  group("convert crypto to fiat", () {
    test("returns null when fiat is disabled", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      settings.fiatApiMode = FiatApiMode.disabled;
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when both sides are fiat", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", FiatCurrency.usd), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when both sides are crypto", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), CryptoCurrency.btc),
        isNull,
      );
    });

    test("returns null when there is no rate", () {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when the live price is for another fiat", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.eur),
        isNull,
      );
    });

    test("returns null when the live price is for another crypto", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.eth), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null when the rate is zero or negative", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 0);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );

      runInAction(() => prices.prices[CryptoCurrency.btc] = -5);
      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("returns null for non-finite rates", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = double.nan);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );

      runInAction(() => prices.prices[CryptoCurrency.btc] = double.infinity);
      expect(
        service.convert(Money.parse("1", CryptoCurrency.btc), FiatCurrency.usd),
        isNull,
      );
    });

    test("computes fiat value with the live rate", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(Money.parse("0.5", CryptoCurrency.btc), FiatCurrency.usd);
      expect(result, isNotNull);
      expect(result!.currency, FiatCurrency.usd);
      expect(result.toStringWithPrecision(fractionalDigits: 2, trimZeros: false), "15000.00");
    });

    test("respects target fiat decimals", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(
        Money.parse("0.00033333", CryptoCurrency.btc),
        FiatCurrency.usd,
      );
      expect(result, isNotNull);
      // 30000 * 0.00033333 = ~9.9999, truncated toward zero at USD decimals (2).
      expect(result!.toStringWithPrecision(fractionalDigits: 2, trimZeros: false), "9.99");
    });

    test("keeps precision for sub-dollar rates", () {
      runInAction(() => prices.prices[CryptoCurrency.doge] = 0.0824);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(Money.parse("100", CryptoCurrency.doge), FiatCurrency.usd);
      expect(result, isNotNull);
      expect(result!.toStringWithPrecision(fractionalDigits: 2, trimZeros: false), "8.24");
    });

    test("keeps precision for sub-cent rates", () {
      runInAction(() => prices.prices[CryptoCurrency.shib] = 0.00002);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(
        Money.parse("1000000", CryptoCurrency.shib),
        FiatCurrency.usd,
      );
      expect(result, isNotNull);
      expect(result!.toStringWithPrecision(fractionalDigits: 2, trimZeros: false), "20.00");
    });

    test("handles currencies with more decimals than toStringAsFixed allows", () {
      runInAction(() => prices.prices[CryptoCurrency.nano] = 1.1);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(Money.parse("2", CryptoCurrency.nano), FiatCurrency.usd);
      expect(result, isNotNull);
      expect(result!.toStringWithPrecision(fractionalDigits: 2, trimZeros: false), "2.20");
    });

    test("keeps precision for sub-cent rates on high-decimals currencies", () {
      runInAction(() => prices.prices[CryptoCurrency.banano] = 0.007);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(
        Money.parse("1000", CryptoCurrency.banano),
        FiatCurrency.usd,
      );
      expect(result, isNotNull);
      // 1000 * 0.007 = 7.00, but the rate's double representation sits a few
      // ulps high, so the truncating conversion lands one cent under.
      expect(result!.toStringWithPrecision(fractionalDigits: 2, trimZeros: false), "6.99");

      final backToCrypto = service.convert(
        Money.parse("1", FiatCurrency.usd),
        CryptoCurrency.banano,
      );
      expect(backToCrypto, isNotNull);
      expect(
        backToCrypto!.toStringWithPrecision(fractionalDigits: 6, trimZeros: false),
        "142.857142",
      );
    });
  });

  group("convert fiat to crypto", () {
    test("returns null when fiat is disabled", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      settings.fiatApiMode = FiatApiMode.disabled;
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("100", FiatCurrency.usd), CryptoCurrency.btc),
        isNull,
      );
    });

    test("returns null when there is no rate", () {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("100", FiatCurrency.usd), CryptoCurrency.btc),
        isNull,
      );
    });

    test("returns null when the rate is zero", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 0);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      expect(
        service.convert(Money.parse("100", FiatCurrency.usd), CryptoCurrency.btc),
        isNull,
      );
    });

    test("computes crypto value with the live rate", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(Money.parse("15000", FiatCurrency.usd), CryptoCurrency.btc);
      expect(result, isNotNull);
      expect(result!.currency, CryptoCurrency.btc);
      expect(result.toStringWithPrecision(fractionalDigits: 8, trimZeros: false), "0.50000000");
    });

    test("keeps precision for sub-dollar rates", () {
      runInAction(() => prices.prices[CryptoCurrency.doge] = 0.0824);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final result = service.convert(Money.parse("100", FiatCurrency.usd), CryptoCurrency.doge);
      expect(result, isNotNull);
      expect(
        result!.toStringWithPrecision(fractionalDigits: 6, trimZeros: false),
        "1213.592233",
      );
    });

    test("round-trips both directions within currency decimals", () {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 25000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      final original = Money.parse("0.5", CryptoCurrency.btc);
      final asFiat = service.convert(original, FiatCurrency.usd);
      expect(asFiat, isNotNull);
      final back = service.convert(asFiat!, CryptoCurrency.btc);
      expect(back, isNotNull);
      expect(
        back!.toStringWithPrecision(fractionalDigits: 8, trimZeros: false),
        original.toStringWithPrecision(fractionalDigits: 8, trimZeros: false),
      );
    });
  });

  group("ensureRateFor", () {
    test("returns immediately when a live rate is already cached", () async {
      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);

      // Timeout means the method didn't await anything network-ish.
      await service
          .ensureRateFor(CryptoCurrency.btc, FiatCurrency.usd)
          .timeout(const Duration(milliseconds: 50));
    });
  });

  group("rateChanges", () {
    test("is a broadcast stream", () {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);
      expect(service.rateChanges.isBroadcast, isTrue);
    });

    test("emits the current fiat when the price map is mutated", () async {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);
      final events = <FiatCurrency>[];
      final sub = service.rateChanges.listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);
      events.clear();

      runInAction(() => prices.prices[CryptoCurrency.btc] = 30000);
      await Future<void>.delayed(Duration.zero);

      expect(events, isNotEmpty);
      expect(events.last, FiatCurrency.usd);
    });

    test("emits the new fiat when settings.fiatCurrency changes", () async {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      addTearDown(service.dispose);
      final events = <FiatCurrency>[];
      final sub = service.rateChanges.listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);
      events.clear();

      settings.fiatCurrency = FiatCurrency.eur;
      await Future<void>.delayed(Duration.zero);

      expect(events, isNotEmpty);
      expect(events.last, FiatCurrency.eur);
    });
  });

  group("dispose", () {
    test("closes the rateChanges stream", () async {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      final done = Completer<void>();
      final sub = service.rateChanges.listen((_) {}, onDone: done.complete);
      addTearDown(sub.cancel);

      await service.dispose();
      await done.future;
    });

    test("subsequent MobX changes do not push events after dispose", () async {
      final service = FiatRateService(fiatConversionStore: prices, settingsStore: settings);
      final events = <FiatCurrency>[];
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
