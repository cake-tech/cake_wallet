import "dart:math" as math;

import "package:cake_wallet/entities/fiat_currency.dart";
import "package:flutter/painting.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart" show Bidi;
import "package:mobx/mobx.dart";

String ltr(String amount) => "\u2066$amount\u2069";

List<String> visualOrder(
  String text,
  List<String> parts, {
  TextDirection direction = TextDirection.ltr,
}) {
  final painter = TextPainter(text: TextSpan(text: text), textDirection: direction)..layout();
  final lefts = <String, double>{};
  for (final part in parts) {
    final start = text.indexOf(part);
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + part.length),
    );
    lefts[part] = boxes.map((box) => box.left).reduce(math.min);
  }
  painter.dispose();

  return [...parts]..sort((a, b) => lefts[a]!.compareTo(lefts[b]!));
}

void main() {
  tearDown(() => FiatCurrency.showsIsoCode = () => false);

  group("FiatCurrency.sign", () {
    const before = false;
    const after = true;

    test("follows the CW-1209 table, with ¥ before the number for JPY and £ for GBP", () {
      final shown = {
        for (final currency in FiatCurrency.all)
          currency.title: (currency.sign, currency.signAfterAmount),
      };

      expect(shown, {
        "AMD": ("֏", before),
        "ARS": (r"AR$", before),
        "AUD": (r"A$", before),
        "BDT": ("৳", before),
        "BGN": ("лв", after),
        "BRL": (r"R$", before),
        "CAD": (r"C$", before),
        "CHF": ("CHF", after),
        "CLP": ("CLP", before),
        "CNY": ("CN¥", after),
        "COP": (r"COL$", before),
        "CZK": ("Kč", after),
        "DKK": ("Dkr", after),
        "EGP": ("E£", before),
        "EUR": ("€", after),
        "GBP": ("£", before),
        "GHS": ("GH₵", before),
        "GTQ": ("Q", before),
        "HKD": (r"HK$", before),
        "HRK": ("kn", after),
        "HUF": ("Ft", after),
        "IDR": ("Rp", before),
        "ILS": ("₪", before),
        "INR": ("₹", before),
        "IRR": ("Rls", before),
        "ISK": ("Ikr", after),
        "JPY": ("¥", before),
        "KES": ("Sh", before),
        "KRW": ("₩", before),
        "MAD": ("د.م", after),
        "MXN": (r"MX$", before),
        "MYR": ("RM", before),
        "NGN": ("₦", before),
        "NOK": ("NKr", after),
        "NZD": (r"NZ$", before),
        "PHP": ("₱", before),
        "PKR": ("Rs", before),
        "PLN": ("zł", after),
        "RON": ("Lei", after),
        "RUB": ("₽", after),
        "SAR": ("﷼", before),
        "SEK": ("kr", after),
        "SGD": (r"S$", before),
        "THB": ("฿", before),
        "TRY": ("₺", before),
        "TWD": (r"NT$", before),
        "UAH": ("₴", before),
        "USD": (r"$", before),
        "VEF": ("Bs.", before),
        "VND": ("₫", after),
        "ZAR": ("R", before),
      });
    });

    test("never shows two currencies with the same symbol", () {
      final currenciesBySign = <String, List<String>>{};
      for (final currency in FiatCurrency.all) {
        currenciesBySign.putIfAbsent(currency.sign, () => []).add(currency.title);
      }

      expect(currenciesBySign.values.where((codes) => codes.length > 1), isEmpty);
    });
  });

  group("FiatCurrency.format", () {
    test("puts a currency sign directly in front of the amount", () {
      expect(FiatCurrency.usd.format("1,234.56"), ltr(r"$1,234.56"));
      expect(FiatCurrency.gbp.format("1,234.56"), ltr("£1,234.56"));
      expect(FiatCurrency.jpy.format("1,234"), ltr("¥1,234"));
      expect(FiatCurrency.cad.format("12.34"), ltr(r"C$12.34"));
      expect(FiatCurrency.inr.format("500.00"), ltr("₹500.00"));
      expect(FiatCurrency.ghs.format("5"), ltr("GH₵5"));
    });

    test("separates a symbol that ends in a letter or a dot", () {
      expect(FiatCurrency.idr.format("12.34"), ltr("Rp 12.34"));
      expect(FiatCurrency.zar.format("12.34"), ltr("R 12.34"));
      expect(FiatCurrency.vef.format("12.34"), ltr("Bs. 12.34"));
      expect(FiatCurrency.clp.format("12"), ltr("CLP 12"));
    });

    test("touches the amount only with a sign before it that ends in neither a letter nor a dot",
        () {
      final spacedBefore = FiatCurrency.all
          .where((currency) => !currency.signAfterAmount && !currency.signTouchesAmount)
          .map((currency) => currency.title);

      expect(
        spacedBefore,
        unorderedEquals(["CLP", "GTQ", "IDR", "IRR", "KES", "MYR", "PKR", "VEF", "ZAR"]),
      );
      expect(FiatCurrency.all.where((c) => c.signAfterAmount && c.signTouchesAmount), isEmpty);
    });

    test("puts the symbol after the amount where the design does, with a space", () {
      expect(FiatCurrency.eur.format("1.234,56"), ltr("1.234,56 €"));
      expect(FiatCurrency.sek.format("12,34"), ltr("12,34 kr"));
      expect(FiatCurrency.chf.format("12.34"), ltr("12.34 CHF"));
      expect(FiatCurrency.pln.format("9,99"), ltr("9,99 zł"));
      expect(FiatCurrency.cny.format("12.34"), ltr("12.34 CN¥"));
      expect(FiatCurrency.vnd.format("1.000"), ltr("1.000 ₫"));
    });

    test("keeps a leading comparison, approximation, equals or minus in front", () {
      expect(FiatCurrency.usd.format("< 0.01"), ltr(r"< $0.01"));
      expect(FiatCurrency.idr.format("< 0.01"), ltr("< Rp 0.01"));
      expect(FiatCurrency.eur.format("< 0.01"), ltr("< 0.01 €"));
      expect(FiatCurrency.usd.format("-5.00"), ltr(r"-$5.00"));
      expect(FiatCurrency.usd.format("~12.34"), ltr(r"~$12.34"));
      expect(FiatCurrency.eur.format("≈ 5.00"), ltr("≈ 5.00 €"));
      expect(FiatCurrency.usd.format("= 12.34"), ltr(r"= $12.34"));
    });

    test("keeps a hidden amount hidden", () {
      expect(FiatCurrency.usd.format("●●●●●"), ltr(r"$●●●●●"));
      expect(FiatCurrency.eur.format("●●●●●"), ltr("●●●●● €"));
    });

    test("leaves an empty amount empty", () {
      expect(FiatCurrency.usd.format(""), "");
      expect(FiatCurrency.eur.format(""), "");
    });
  });

  group("right-to-left symbols", () {
    testWidgets("stay on their side of the amount", (tester) async {
      expect(
        visualOrder(FiatCurrency.sar.format("1,234.56"), ["﷼", "1,234.56"]),
        ["﷼", "1,234.56"],
      );
      expect(
        visualOrder(FiatCurrency.mad.format("1,234.56"), ["1,234.56", "د.م"]),
        ["1,234.56", "د.م"],
      );
    });

    testWidgets("keep the text around them in reading order", (tester) async {
      for (final currency in [FiatCurrency.sar, FiatCurrency.mad]) {
        final range = "${currency.format("5.00")} - ${currency.format("100.00")}";
        final redirect = "${currency.format("100.00")} → 0.00123 BTC";

        expect(visualOrder(range, ["5.00", "100.00"]), ["5.00", "100.00"], reason: currency.title);
        expect(
          visualOrder(redirect, ["100.00", "→", "0.00123"]),
          ["100.00", "→", "0.00123"],
          reason: currency.title,
        );
      }
    });
  });

  group("in a right-to-left UI", () {
    testWidgets("reads every amount as it does in English", (tester) async {
      final amounts = {
        FiatCurrency.usd.format("1,234.56"): [r"$", "1,234.56"],
        FiatCurrency.eur.format("1.234,56"): ["1.234,56", "€"],
        FiatCurrency.idr.format("< 0.01"): ["<", "Rp", "0.01"],
        FiatCurrency.usd.format("-5.00"): ["-", r"$", "5.00"],
        FiatCurrency.usd.format("~12.34"): ["~", r"$", "12.34"],
        FiatCurrency.eur.format("≈ 5.00"): ["≈", "5.00", "€"],
        FiatCurrency.usd.format("= 12.34"): ["=", r"$", "12.34"],
        FiatCurrency.usd.format("●●●●●"): [r"$", "●●●●●"],
        FiatCurrency.sar.format("1,234.56"): ["﷼", "1,234.56"],
        FiatCurrency.mad.format("1,234.56"): ["1,234.56", "د.م"],
      };

      for (final MapEntry(key: amount, value: parts) in amounts.entries) {
        expect(visualOrder(amount, parts, direction: TextDirection.rtl), parts, reason: amount);
      }
    });

    testWidgets("keeps an isolated symbol in order inside right-to-left text", (tester) async {
      for (final currency in FiatCurrency.all) {
        final symbol = currency.symbolSign;
        if (symbol.length < 2 || Bidi.hasAnyRtl(symbol)) {
          continue;
        }
        final head = symbol.substring(0, symbol.length - 1);
        final tail = symbol.substring(symbol.length - 1);
        final option = "الرمز (${currency.isolatedSymbolSign})";

        expect(
          visualOrder(option, [head, tail], direction: TextDirection.rtl),
          [head, tail],
          reason: currency.title,
        );
      }
    });

    testWidgets("keeps an amount in order inside right-to-left text", (tester) async {
      final sentence = "المبلغ ${FiatCurrency.eur.format("5.00")}";

      expect(visualOrder(sentence, ["5.00", "€"], direction: TextDirection.rtl), ["5.00", "€"]);
    });
  });

  group("ISO code format", () {
    setUp(() => FiatCurrency.showsIsoCode = () => true);

    test("puts the code in front of every amount", () {
      expect(FiatCurrency.usd.format("1,234.56"), ltr("USD 1,234.56"));
      expect(FiatCurrency.eur.format("1.234,56"), ltr("EUR 1.234,56"));
      expect(FiatCurrency.jpy.format("1,234"), ltr("JPY 1,234"));
      expect(FiatCurrency.usd.format("< 0.01"), ltr("< USD 0.01"));
    });

    test("uses the code as the sign, before the amount and spaced from it", () {
      for (final currency in FiatCurrency.all) {
        expect(currency.sign, currency.title);
        expect(currency.signAfterAmount, isFalse, reason: currency.title);
        expect(currency.signTouchesAmount, isFalse, reason: currency.title);
      }
    });

    test("keeps the symbol in the currency name", () {
      expect(FiatCurrency.cad.label, r"CAD (C$)");
      expect(FiatCurrency.cad.symbolSign, r"C$");
    });
  });

  test("reformats amounts that MobX tracks when the format changes", () {
    final showsIsoCode = Observable(false);
    FiatCurrency.showsIsoCode = () => showsIsoCode.value;
    final shown = <String>[];
    final dispose = autorun((_) => shown.add(FiatCurrency.eur.format("5")));
    addTearDown(dispose);

    runInAction(() => showsIsoCode.value = true);

    expect(shown, [ltr("5 €"), ltr("EUR 5")]);
  });

  group("FiatCurrency.label", () {
    test("names the currency by code with its symbol", () {
      expect(FiatCurrency.usd.label, r"USD ($)");
      expect(FiatCurrency.eur.label, "EUR (€)");
      expect(FiatCurrency.cad.label, r"CAD (C$)");
      expect(FiatCurrency.sek.label, "SEK (kr)");
    });

    test("is the bare code when the symbol is the code", () {
      expect(FiatCurrency.chf.label, "CHF");
      expect(FiatCurrency.clp.label, "CLP");
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
