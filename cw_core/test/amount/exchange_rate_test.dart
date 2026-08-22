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

  group('fromAmounts', () {
    test('derives rate from amounts: 10 BTC for 100 ETH is 1 BTC = 10 ETH', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('10', CryptoCurrency.btc),
        Money.parse('100', CryptoCurrency.eth),
      );

      expect(rate.base, CryptoCurrency.btc);
      expect(rate.quote, Money.parse('10', CryptoCurrency.eth));
    });

    test('base currency with 18 decimal places: 2 ETH for 5.000 EUR', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('2', CryptoCurrency.eth),
        Money.parse('5000.00', EUR),
      );

      expect(rate.base, CryptoCurrency.eth);
      expect(rate.quote, Money.parse('2500.00', EUR));
    });

    test('fiat base currency: 60.000 EUR for 1 BTC', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('60000.00', EUR),
        Money.parse('1', CryptoCurrency.btc),
      );

      expect(rate.base, EUR);
      expect(rate.quote, Money.parse('0.00001667', CryptoCurrency.btc));
    });

    test('same currency on both sides: 2 BTC for 2 BTC is a rate of 1', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('2', CryptoCurrency.btc),
        Money.parse('2', CryptoCurrency.btc),
      );

      expect(rate.quote, Money.parse('1', CryptoCurrency.btc));
    });

    test('derived rate converts the from amount back into the to amount', () {
      final from = Money.parse('0.5', CryptoCurrency.btc);
      final to = Money.parse('30000.00', EUR);
      final rate = ExchangeRate.fromAmounts(from, to);

      expect(rate.quote, Money.parse('60000.00', EUR));
      expect(rate.convert(from), to);
    });

    test('base currency without decimal places: 500 JPY for 5 EUR', () {
      final rate = ExchangeRate.fromAmounts(
        Money.fromInt(500, JPY),
        Money.parse('5.00', EUR),
      );

      expect(rate.quote, Money.parse('0.01', EUR));
    });

    test('quote is rounded to the smallest unit of the to currency', () {
      final roundedDown = ExchangeRate.fromAmounts(
        Money.parse('3', CryptoCurrency.btc),
        Money.parse('1.00', EUR),
      );
      expect(roundedDown.quote, Money.parse('0.33', EUR));

      final roundedUp = ExchangeRate.fromAmounts(
        Money.parse('2', CryptoCurrency.btc),
        Money.parse('0.01', EUR),
      );
      expect(roundedUp.quote, Money.parse('0.01', EUR));
    });

    test('rounding the quote makes the round trip lossy', () {
      final from = Money.parse('3', CryptoCurrency.btc);
      final rate = ExchangeRate.fromAmounts(from, Money.parse('1.00', EUR));

      expect(rate.convert(from), Money.parse('0.99', EUR));
    });

    test('negative amounts keep their sign', () {
      final negativeTo = ExchangeRate.fromAmounts(
        Money.parse('4', CryptoCurrency.btc),
        Money.parse('-200.00', EUR),
      );
      expect(negativeTo.quote, Money.parse('-50.00', EUR));

      final negativeRounded = ExchangeRate.fromAmounts(
        Money.parse('2', CryptoCurrency.btc),
        Money.fromInt(-1, EUR),
      );
      expect(negativeRounded.quote, Money.fromInt(-1, EUR));
    });

    test('to amount too small for the quote currency gives a zero rate', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('3', CryptoCurrency.btc),
        Money.fromInt(1, EUR),
      );

      expect(rate.quote, Money.zero(EUR));
    });

    test('single base unit from amount: 1 sat for 1 EUR', () {
      final rate = ExchangeRate.fromAmounts(
        Money(BigInt.one, CryptoCurrency.btc),
        Money.parse('1.00', EUR),
      );

      expect(rate.quote, Money.parse('100000000.00', EUR));
    });

    test('no int overflow with large amounts', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('21000000', CryptoCurrency.btc),
        Money.parse('1260000000000.00', EUR),
      );

      expect(rate.quote, Money.parse('60000.00', EUR));
    });

    test('zero to amount gives a zero rate', () {
      final rate = ExchangeRate.fromAmounts(
        Money.parse('1', CryptoCurrency.btc),
        Money.zero(EUR),
      );

      expect(rate.quote, Money.zero(EUR));
    });

    test('throws on a zero from amount', () {
      expect(
        () => ExchangeRate.fromAmounts(
          Money.zero(CryptoCurrency.btc),
          Money.parse('1.00', EUR),
        ),
        throwsArgumentError,
      );
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
  String get serialized => "fiat.$symbol";

  @override
  Money parseAmount(String value) => Money.parse(value, this);

  @override
  Money? tryParseAmount(String value) => Money.tryParse(value, this);
}

const EUR = FiatCurrency(symbol: 'EUR', countryCode: "eur", fullName: "Euro");
const USD = FiatCurrency(symbol: 'USD', countryCode: "usd", fullName: "US Dollar");
const JPY = FiatCurrency(symbol: 'JPY', countryCode: "jpn", fullName: "Japanese Yen", decimals: 0);
