import 'package:cw_core/amount/exchange_rate.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExchangeRate', () {
    final rate = ExchangeRate(
      base: CryptoCurrency.btc,
      quote: Money.parse("60000", EUR),
    );

    test('convert base currency to quote currency: 1 BTC to 60.000 EUR', () {
      final result = rate.convert(Money.parse('1', CryptoCurrency.btc));
      expect(result, Money.parse("60000.00", EUR));
    });

    test('convert base currency to quote currency: 0.5 BTC to 30.000 EUR', () {
      final result = rate.convert(Money.parse('0.5', CryptoCurrency.btc));
      expect(result, Money.parse("30000.00", EUR));
    });

    test('convert quote currency to base currency: 60.000 EUR to 1 BTC', () {
      final result = rate.convert(Money.parse("60000.00", EUR));
      expect(result, Money.parse('1', CryptoCurrency.btc));
    });

    test('convert quote currency to base currency: 30 EUR to 0.0005 BTC', () {
      final result = rate.convert(Money.parse("30.00", EUR));
      expect(result, Money.parse('0.0005', CryptoCurrency.btc));
    });
  });

  group('Edge Cases', () {
    final rate = ExchangeRate(
      base: CryptoCurrency.btc,
      quote: Money.parse("60000", EUR),
    );

    test('Converting zero turns into zero', () {
      expect(rate.convert(Money.zero(CryptoCurrency.btc)), Money.zero(EUR));
      expect(rate.convert(Money.zero(EUR)), Money.zero(CryptoCurrency.btc));
    });

    test('truncate to smallest unit', () {
      final result = rate.convert(Money(BigInt.one, CryptoCurrency.btc)); // 1 sat
      expect(result, Money.zero(EUR));
    });

    test('Truncate base unit of base currency', () {
      final result = rate.convert(Money(BigInt.one, EUR));
      expect(result, Money.fromInt(16, CryptoCurrency.btc));
    });

    test('No int overflow with large numbers', () {
      final allBtc = Money.parse('21000000', CryptoCurrency.btc);
      final result = rate.convert(allBtc);
      expect(result, Money(BigInt.from(126000000000000), EUR));
    });

    test('truncation for negative amounts', () {
      final result = rate.convert(Money.fromInt(-1, EUR));
      expect(result, Money.fromInt(-16, CryptoCurrency.btc));
    });

    test('Base currency without decimals places: JPY', () {
      final rate = ExchangeRate(
        base: JPY,
        quote: Money.fromInt(1, EUR),
      );

      expect(rate.convert(Money.fromInt(500, JPY)), Money.fromInt(500, EUR));
      expect(rate.convert(Money.fromInt(500, EUR)), Money.fromInt(500, JPY));
    });

    test('Base currency with 18 decimals places: ETH', () {
      final rate = ExchangeRate(
        base: CryptoCurrency.eth,
        quote: Money.fromInt(300000, EUR),
      );

      expect(rate.convert(Money.parse('1', CryptoCurrency.eth)), Money.fromInt(300000, EUR));
      expect(rate.convert(Money.fromInt(3000, EUR)), Money.parse('0.01', CryptoCurrency.eth));
    });

    test('Smalles base unit is less than smalles base unit of quote', () {
      final rate = ExchangeRate(
        base: CryptoCurrency.eth,
        quote: Money.fromInt(300000, EUR),
      );
      expect(rate.convert(Money(BigInt.one, CryptoCurrency.eth)), Money(BigInt.zero, EUR));
    });

    test('Cannot convert currency outside of pair', () {
      expect(() => rate.convert(Money.parse("60000", USD)), throwsArgumentError);
    });

    test('handle quote being 0 correctly', () {
      final zeroRate = ExchangeRate(
        base: CryptoCurrency.btc,
        quote: Money(BigInt.zero, EUR),
      );
      expect(zeroRate.convert(Money.fromInt(100, CryptoCurrency.btc)), Money(BigInt.zero, EUR));
      expect(zeroRate.convert(Money.fromInt(100, EUR)), Money(BigInt.zero, CryptoCurrency.btc));
    });
  });

  group("tryFromDouble", () {
    test("stores the rate directly when it is above the crossover", () {
      final rate = ExchangeRate.tryFromDouble(
        base: CryptoCurrency.btc,
        quoteCurrency: EUR,
        rate: 60000,
      );

      expect(rate!.base, CryptoCurrency.btc);
      expect(rate.quote, Money.parse("60000", EUR));
      expect(rate.convert(Money.parse("1", CryptoCurrency.btc)), Money.parse("60000", EUR));
    });

    test("stores a small rate flipped to keep its precision", () {
      // 0.00002 EUR would round to 0.00 in a 2-decimal quote, so the pair is
      // stored as 50000 per EUR instead.
      final rate = ExchangeRate.tryFromDouble(
        base: CryptoCurrency.btc,
        quoteCurrency: EUR,
        rate: 0.00002,
      );

      expect(rate!.base, EUR);
      expect(rate.quote, Money.parse("50000", CryptoCurrency.btc));
      expect(rate.convert(Money.parse("100000", CryptoCurrency.btc)), Money.parse("2", EUR));
    });

    test("rate exactly at the crossover stores directly", () {
      // The crossover for an 8-decimal base and a 2-decimal quote is sqrt(10^6).
      final rate = ExchangeRate.tryFromDouble(
        base: CryptoCurrency.btc,
        quoteCurrency: EUR,
        rate: 1000,
      );

      expect(rate!.base, CryptoCurrency.btc);
    });

    test("rate just below the crossover stores flipped", () {
      final rate = ExchangeRate.tryFromDouble(
        base: CryptoCurrency.btc,
        quoteCurrency: EUR,
        rate: 999,
      );

      expect(rate!.base, EUR);
    });

    test("same-decimal pair flips below 1", () {
      final direct = ExchangeRate.tryFromDouble(base: EUR, quoteCurrency: USD, rate: 1.08);
      final flipped = ExchangeRate.tryFromDouble(base: EUR, quoteCurrency: USD, rate: 0.93);

      expect(direct!.base, EUR);
      expect(flipped!.base, USD);
    });

    test("returns null for zero, negative and non-finite rates", () {
      const base = CryptoCurrency.btc;
      expect(ExchangeRate.tryFromDouble(base: base, quoteCurrency: EUR, rate: 0.0), isNull);
      expect(ExchangeRate.tryFromDouble(base: base, quoteCurrency: EUR, rate: -1.5), isNull);
      expect(ExchangeRate.tryFromDouble(base: base, quoteCurrency: EUR, rate: double.nan), isNull);
      expect(
        ExchangeRate.tryFromDouble(base: base, quoteCurrency: EUR, rate: double.infinity),
        isNull,
      );
    });

    test("returns null when the flipped rate overflows to infinity", () {
      // 1/5e-324 is infinite, so tryToMoney returns null instead of throwing.
      final rate = ExchangeRate.tryFromDouble(
        base: CryptoCurrency.btc,
        quoteCurrency: EUR,
        rate: 5e-324,
      );

      expect(rate, isNull);
    });

    test("returns null for rates at or above 1e21", () {
      // toStringAsFixed switches to exponential notation there, which
      // Money cannot parse, so tryToMoney returns null.
      final rate = ExchangeRate.tryFromDouble(
        base: CryptoCurrency.btc,
        quoteCurrency: EUR,
        rate: 1e22,
      );

      expect(rate, isNull);
    });
  });
}

class FiatCurrency implements Currency {
  const FiatCurrency({
    required this.symbol,
    required this.countryCode,
    required this.fullName,
    this.decimals = 2,
  });

  final String countryCode;

  @override
  final String fullName;

  @override
  final int decimals;

  @override
  final String symbol;

  @override
  String? get iconPath => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  String? get tag => throw UnimplementedError();

  @override
  Money parseAmount(String value) => Money.parse(value, this);

  @override
  Money? tryParseAmount(String value) => Money.tryParse(value, this);
}

const EUR = FiatCurrency(symbol: 'EUR', countryCode: "eur", fullName: "Euro");
const USD = FiatCurrency(symbol: 'USD', countryCode: "usd", fullName: "US Dollar");
const JPY = FiatCurrency(symbol: 'JPY', countryCode: "jpn", fullName: "Japanese Yen", decimals: 0);
