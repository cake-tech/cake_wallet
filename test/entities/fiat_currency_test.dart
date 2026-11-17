import "package:cake_wallet/entities/fiat_currency.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";

void main() {
  // Has to run first: the sign table is built on first use, so only the first
  // lookup shows whether building it depends on the app language.
  test("FiatCurrency.sign resolves while the app language has no number formats", () {
    final previous = Intl.defaultLocale;
    addTearDown(() => Intl.defaultLocale = previous);

    for (final locale in ["gn", "ha", "yo"]) {
      Intl.defaultLocale = locale;

      expect(FiatCurrency.usd.sign, r"$", reason: locale);
    }
  });

  group("FiatCurrency.sign", () {
    test("is the currency's own sign when no other currency uses it", () {
      expect(FiatCurrency.usd.sign, r"$");
      expect(FiatCurrency.eur.sign, "€");
      expect(FiatCurrency.gbp.sign, "£");
      expect(FiatCurrency.jpy.sign, "¥");
      expect(FiatCurrency.brl.sign, r"R$");
      expect(FiatCurrency.pln.sign, "zł");
      expect(FiatCurrency.tur.sign, "TL");
    });

    test("uses CLDR's prefixed form for AUD, CAD, HKD, MXN, NZD and CNY", () {
      expect(FiatCurrency.aud.sign, r"A$");
      expect(FiatCurrency.cad.sign, r"CA$");
      expect(FiatCurrency.hkd.sign, r"HK$");
      expect(FiatCurrency.mxn.sign, r"MX$");
      expect(FiatCurrency.nzd.sign, r"NZ$");
      expect(FiatCurrency.cny.sign, "CN¥");
    });

    test("falls back to the code when the currency has no sign of its own", () {
      for (final currency in [
        FiatCurrency.ars,
        FiatCurrency.clp,
        FiatCurrency.cop,
        FiatCurrency.sgd,
        FiatCurrency.dkk,
        FiatCurrency.isk,
        FiatCurrency.nok,
        FiatCurrency.sek,
        FiatCurrency.chf,
        FiatCurrency.ghs,
        FiatCurrency.ron,
      ]) {
        expect(currency.sign, currency.title);
      }
    });

    test("never shows two currencies with the same sign", () {
      final currenciesBySign = <String, List<String>>{};
      for (final currency in FiatCurrency.all) {
        currenciesBySign.putIfAbsent(currency.sign, () => []).add(currency.title);
      }

      expect(currenciesBySign.values.where((codes) => codes.length > 1), isEmpty);
      expect(currenciesBySign[r"$"], ["USD"]);
    });
  });

  group("FiatCurrency.label", () {
    test("names the currency by code with its short sign", () {
      expect(FiatCurrency.usd.label, r"USD ($)");
      expect(FiatCurrency.eur.label, "EUR (€)");
      expect(FiatCurrency.cad.label, r"CAD ($)");
      expect(FiatCurrency.sek.label, "SEK (kr)");
    });

    test("is the bare code when the currency has no sign", () {
      expect(FiatCurrency.chf.label, "CHF");
    });

    test("keeps the text the Display settings row shipped with for every currency", () {
      for (final currency in FiatCurrency.all) {
        final code = currency.title;
        final symbol = NumberFormat.simpleCurrency(locale: "en", name: code).currencySymbol;

        expect(currency.label, symbol == code ? code : "$code ($symbol)", reason: code);
      }
    });
  });

  group("FiatCurrency.format", () {
    test("puts a currency sign directly in front of the amount", () {
      expect(FiatCurrency.usd.format("1,234.56"), r"$1,234.56");
      expect(FiatCurrency.eur.format("1,234.56"), "€1,234.56");
      expect(FiatCurrency.brl.format("12.50"), r"R$12.50");
      expect(FiatCurrency.cad.format("1,234.56"), r"CA$1,234.56");
      expect(FiatCurrency.cny.format("12.34"), "CN¥12.34");
      expect(FiatCurrency.twd.format("5"), r"NT$5");
    });

    test("separates a sign made of letters from the amount", () {
      expect(FiatCurrency.sek.format("1,234.56"), "SEK 1,234.56");
      expect(FiatCurrency.pln.format("9.99"), "zł 9.99");
      expect(FiatCurrency.czk.format("9.99"), "Kč 9.99");
    });

    test("uses the code for a currency without a sign", () {
      expect(FiatCurrency.chf.format("1,234.56"), "CHF 1,234.56");
    });

    test("keeps a leading comparison or minus in front of the sign", () {
      expect(FiatCurrency.usd.format("< 0.01"), r"< $0.01");
      expect(FiatCurrency.sek.format("< 0.01"), "< SEK 0.01");
      expect(FiatCurrency.usd.format("-5.00"), r"-$5.00");
    });

    test("leaves the amount text itself untouched", () {
      expect(FiatCurrency.eur.format("1.234,56"), "€1.234,56");
      expect(FiatCurrency.usd.format("●●●●●"), r"$●●●●●");
    });
  });

  group("FiatCurrency as a value sent to providers and storage", () {
    test("still serializes to the ISO code", () {
      for (final currency in FiatCurrency.all) {
        final code = currency.raw;

        expect(code, matches(RegExp(r"^[A-Z]{3}$")));
        expect(currency.toString(), code);
        expect(currency.title, code);
        expect(currency.symbol, code);
        expect(currency.name, code);
        expect(currency.serialize(), code);
      }
    });
  });
}
