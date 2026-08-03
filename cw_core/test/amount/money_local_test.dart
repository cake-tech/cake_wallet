import "package:cw_core/amount/money.dart";
import "package:cw_core/amount/money_local.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";

final _btc012 = Money.fromInt(12345678, CryptoCurrency.btc); // 0.12345678 BTC
final _btcTrailing = Money.fromInt(12000000, CryptoCurrency.btc); // 0.12 BTC
final _btcGrouping = Money.fromInt(123450000000, CryptoCurrency.btc); // 1234.5 BTC
final _xmrHalf = Money.fromInt(500000000000, CryptoCurrency.xmr); // 0.5 XMR

void main() {
  group("toLocalStringWithPrecision", () {
    test("localizes grouping (en_US)", () {
      expect(_btcGrouping.toLocalStringWithPrecision(locale: "en_US"), "1,234.5");
    });

    test("no grouping for sub-1 values", () {
      expect(_btc012.toLocalStringWithPrecision(locale: "en_US"), "0.12345678");
    });

    test("swaps grouping/decimal separators (de_DE)", () {
      expect(_btcGrouping.toLocalStringWithPrecision(locale: "de_DE"), "1.234,5");
    });

    test("base unit renders integer sats with grouping", () {
      expect(
        _btc012.toLocalStringWithPrecision(useBaseUnit: true, locale: "en_US"),
        "12,345,678",
      );
    });

    test("fractionalDigits truncates (does not round)", () {
      // 0.12345678 -> 0.12 (NOT 0.13).
      expect(_btc012.toLocalStringWithPrecision(fractionalDigits: 2, locale: "en_US"), "0.12");
    });

    test("trimZeros:false keeps trailing zeros", () {
      expect(
        _btcTrailing.toLocalStringWithPrecision(trimZeros: false, locale: "en_US"),
        "0.12000000",
      );
    });

    test("respects a higher-precision currency (XMR)", () {
      expect(_xmrHalf.toLocalStringWithPrecision(locale: "en_US"), "0.5");
    });

    test("falls back to the ambient Intl locale when locale is null", () {
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);
      Intl.defaultLocale = "de_DE";

      // Proves the extension passes null through to NumberFormat rather than
      // hardcoding a locale.
      expect(_btcGrouping.toLocalStringWithPrecision(), "1.234,5");
    });
  });

  group("toLocalStringWithSymbol", () {
    test("suffixes the symbol by default", () {
      expect(_btcGrouping.toLocalStringWithSymbol(locale: "en_US"), "1,234.5 BTC");
    });

    test("prefixes the symbol when withSymbolPrefix is true", () {
      expect(
        _btcGrouping.toLocalStringWithSymbol(withSymbolPrefix: true, locale: "en_US"),
        "BTC 1,234.5",
      );
    });

    test("suffixes the base-unit ticker", () {
      expect(
        _btc012.toLocalStringWithSymbol(useBaseUnit: true, locale: "en_US"),
        "12,345,678 sats",
      );
    });

    test("prefixes the base-unit ticker", () {
      expect(
        _btc012.toLocalStringWithSymbol(
          useBaseUnit: true,
          withSymbolPrefix: true,
          locale: "en_US",
        ),
        "sats 12,345,678",
      );
    });

    test("prefix respects de_DE separators", () {
      expect(
        _btcGrouping.toLocalStringWithSymbol(withSymbolPrefix: true, locale: "de_DE"),
        "BTC 1.234,5",
      );
    });

    test("uses the currency symbol for non-BTC", () {
      expect(_xmrHalf.toLocalStringWithSymbol(locale: "en_US"), "0.5 XMR");
    });

    test("forwards fractionalDigits to the precision string", () {
      expect(_btc012.toLocalStringWithSymbol(fractionalDigits: 2, locale: "en_US"), "0.12 BTC");
    });

    test("forwards trimZeros to the precision string", () {
      expect(
        _btcTrailing.toLocalStringWithSymbol(trimZeros: false, locale: "en_US"),
        "0.12000000 BTC",
      );
    });
  });

  group("negative amounts", () {
    test("keeps the sign when the integer part is non-zero", () {
      expect((-_btcGrouping).toLocalStringWithSymbol(locale: "en_US"), "-1,234.5 BTC");
    });

    // NOTE: currently fails. For |amount| < 1 the sign is dropped:
    // formatFixed yields "-0.5", but _withLocalSeparator re-parses the integer
    // part and int.tryParse("-0") == 0, so the "-" is lost -> "0.5 XMR".
    // Fix in _withLocalSeparator by capturing the sign before parsing, e.g.
    //   final negative = amount.startsWith("-");
    //   ... then re-apply it to the formatted result.
    test("keeps the sign for sub-1 amounts", () {
      expect((-_xmrHalf).toLocalStringWithSymbol(locale: "en_US"), "-0.5 XMR");
    });
  });
}
