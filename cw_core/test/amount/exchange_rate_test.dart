import 'package:cw_core/amount/exchange_rate.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

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
        quote: Money(BigInt.zero, EUR, EUR.decimals),
      );
      expect(zeroRate.convert(Money.fromInt(100, CryptoCurrency.btc)), Money(BigInt.zero, EUR));
      expect(zeroRate.convert(Money.fromInt(100, EUR)), Money(BigInt.zero, CryptoCurrency.btc));
    });

    test('handle super low quote correctly', () {
      final zeroRate = ExchangeRate(
        base: CryptoCurrency.shib,
        quote: Money.parse("0.00000444", EUR, strictParsing: false),
      );

      expect(
        zeroRate.convert(Money.parse("1", CryptoCurrency.shib)),
        Money.parse("0.00000444", EUR, strictParsing: false),
      );
      expect(
        zeroRate.convert(Money.fromInt(10000, EUR)),
        Money.parse("22522522.522522522522522522", CryptoCurrency.shib),
      );

      expect(
        zeroRate.convert(Money.parse("200", CryptoCurrency.shib)),
        Money.parse("0.000888", EUR, strictParsing: false),
      );
    });

    group('Precision and scale', () {
      final rate = ExchangeRate(base: CryptoCurrency.btc, quote: Money.parse("60000", EUR));

      test('convert is insensitive to the input scale (forward)', () {
        // Same value, three different internal scales.
        final coarse = Money(BigInt.one, CryptoCurrency.btc, 0);
        final normal = Money.parse("1", CryptoCurrency.btc);
        final fine = Money.parse("1.000000000000000000", CryptoCurrency.btc, strictParsing: false);

        expect(rate.convert(coarse), Money.parse("60000.00", EUR));
        expect(rate.convert(normal), Money.parse("60000.00", EUR));
        expect(rate.convert(fine), Money.parse("60000.00", EUR));
      });

      test('convert is insensitive to the input scale (reverse)', () {
        expect(
          rate.convert(Money(BigInt.one, EUR, 0)), // €1 at scale 0
          rate.convert(Money.parse("1", EUR)), // €1 at scale 2
        );
      });

      test('sub-unit precision in the input does not leak into the result', () {
        // ad = 18 here, well past BTC's 8. The divisor must cancel the *amount's*
        // scale, not the base currency's.
        final overPrecise =
            Money.parse("1.000000000000000001", CryptoCurrency.btc, strictParsing: false);

        expect(rate.convert(overPrecise), Money.parse("60000.00", EUR));
      });

      test('the result carries the quote scale, not the currency default', () {
        final preciseRate = ExchangeRate(
          base: CryptoCurrency.btc,
          quote: Money.parse("60000.123456", EUR, strictParsing: false),
        );

        final result = preciseRate.convert(Money.parse("1", CryptoCurrency.btc));

        expect(result.decimals, 6);
        expect(result, Money.parse("60000.123456", EUR, strictParsing: false));
      });

      test('a quote scale finer than the currency survives the round trip', () {
        final preciseRate = ExchangeRate(
          base: CryptoCurrency.btc,
          quote: Money.parse("60000.50", EUR, strictParsing: false),
        );

        expect(
          preciseRate.convert(preciseRate.convert(Money.parse("1", CryptoCurrency.btc))),
          Money.parse("1", CryptoCurrency.btc),
        );
      });
    });

    group('Truncation', () {
      final rate = ExchangeRate(base: CryptoCurrency.btc, quote: Money.parse("60000", EUR));

      test('truncates rather than rounding, even past the halfway point', () {
        // 9 sats = 0.54 cents. Rounding would give 1.
        expect(rate.convert(Money(BigInt.from(9), CryptoCurrency.btc)), Money.zero(EUR));
        // 1 cent = 16.66 sats. Rounding would give 17.
        expect(rate.convert(Money(BigInt.one, EUR)), Money.fromInt(16, CryptoCurrency.btc));
      });

      test('truncates toward zero for negatives, not downward', () {
        // -0.54 cents must be 0, not -1.
        expect(rate.convert(Money(BigInt.from(-9), CryptoCurrency.btc)), Money.zero(EUR));
        expect(rate.convert(Money(BigInt.from(-1), EUR)), Money.fromInt(-16, CryptoCurrency.btc));
      });

      test('truncation is symmetric around zero', () {
        final positive = rate.convert(Money(BigInt.from(7), EUR));
        final negative = rate.convert(Money(BigInt.from(-7), EUR));

        expect(negative, -positive);
      });

      test('round trip loses less than one quote base unit', () {
        final original = Money.parse("0.12345678", CryptoCurrency.btc);
        final back = rate.convert(rate.convert(original));
        final oneQuoteUnitInBaseUnits =
            BigInt.from(10).pow(CryptoCurrency.btc.decimals) ~/ rate.quote.amount;

        expect(
          (original - back).amount.abs(),
          lessThanOrEqualTo(oneQuoteUnitInBaseUnits + BigInt.one),
        );
      });

      test('round trip never inflates the amount', () {
        // Both truncations round toward zero, so the result can only shrink.
        for (final source in ["0.12345678", "1", "0.5", "21000000"]) {
          final original = Money.parse(source, CryptoCurrency.btc);
          expect(
            rate.convert(rate.convert(original)) <= original,
            isTrue,
            reason: "round trip grew $source",
          );
        }
      });

      test('a value below one base unit of the quote collapses to zero', () {
        final back = rate.convert(rate.convert(Money(BigInt.one, CryptoCurrency.btc)));

        expect(back.isZero, isTrue);
      });
    });

    group('Extreme decimal spreads', () {
      test('30 decimals against 0 decimals: NANO/JPY', () {
        final rate = ExchangeRate(base: CryptoCurrency.nano, quote: Money.parse("150", JPY));

        expect(rate.convert(Money.parse("1", CryptoCurrency.nano)), Money.fromInt(150, JPY));
        expect(rate.convert(Money.fromInt(150, JPY)), Money.parse("1", CryptoCurrency.nano));
        expect(rate.convert(Money.fromInt(1, JPY)).decimals, 30);
      });

      test('0 decimals against 18 decimals: JPY/SHIB', () {
        final rate = ExchangeRate(base: JPY, quote: Money.parse("2500", CryptoCurrency.shib));

        expect(rate.convert(Money.fromInt(2, JPY)), Money.parse("5000", CryptoCurrency.shib));
        expect(rate.convert(Money.parse("5000", CryptoCurrency.shib)), Money.fromInt(2, JPY));
      });

      test('no overflow at the extremes', () {
        final rate = ExchangeRate(
          base: CryptoCurrency.shib,
          quote: Money.parse("0.00000444", EUR, strictParsing: false),
        );
        final totalSupply = Money.parse("589000000000000", CryptoCurrency.shib);

        expect(rate.convert(totalSupply).isNegative, isFalse);
        expect(rate.convert(rate.convert(totalSupply)) <= totalSupply, isTrue);
      });
    });

    group('Degenerate pairs', () {
      test('identity pair returns the amount untouched', () {
        final identity = ExchangeRate(base: EUR, quote: Money.parse("1", EUR));

        expect(identity.convert(Money.parse("42.42", EUR)), Money.parse("42.42", EUR));
        expect(identity.convert(Money.zero(EUR)), Money.zero(EUR));
      });

      test('a same-currency pair silently ignores its own rate', () {
        final bogus = ExchangeRate(base: EUR, quote: Money.parse("2", EUR));
        expect(bogus.convert(Money.parse("10", EUR)), Money.parse("10", EUR));
      });

      test('a rate of exactly one is a no-op in both directions', () {
        final rate = ExchangeRate(base: JPY, quote: Money.fromInt(100, EUR));

        expect(rate.convert(Money.fromInt(7, JPY)), Money.fromInt(700, EUR));
        expect(rate.convert(Money.fromInt(700, EUR)), Money.fromInt(7, JPY));
      });

      test('negative quotes propagate their sign', () {
        final inverted = ExchangeRate(base: CryptoCurrency.btc, quote: Money.parse("-60000", EUR));

        expect(
          inverted.convert(Money.parse("1", CryptoCurrency.btc)),
          Money.parse("-60000.00", EUR),
        );
        expect(
          inverted.convert(Money.parse("-60000.00", EUR)),
          Money.parse("1", CryptoCurrency.btc),
        );
      });

      test('zero amount with a zero quote', () {
        final zeroRate = ExchangeRate(base: CryptoCurrency.btc, quote: Money.zero(EUR));

        expect(zeroRate.convert(Money.zero(CryptoCurrency.btc)), Money.zero(EUR));
        expect(zeroRate.convert(Money.zero(EUR)), Money.zero(CryptoCurrency.btc));
      });

      test('rejects a foreign currency in both slots', () {
        final rate = ExchangeRate(base: CryptoCurrency.btc, quote: Money.parse("60000", EUR));

        expect(() => rate.convert(Money.parse("1", CryptoCurrency.xmr)), throwsArgumentError);
        expect(() => rate.convert(Money.parse("1", USD)), throwsArgumentError);
      });
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
