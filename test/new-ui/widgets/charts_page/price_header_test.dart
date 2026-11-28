import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/charts_page/price_header.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

void main() {
  Future<void> pumpHeader(
    WidgetTester tester,
    FiatCurrency currency, {
    TextDirection direction = TextDirection.ltr,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: ChartViewPriceHeader(price: "...", fiatCurrency: currency, highlight: false),
            ),
          ),
        ),
      );

  double gapBetween(WidgetTester tester, String left, String right) =>
      tester.getTopLeft(find.text(right)).dx - tester.getTopRight(find.text(left)).dx;

  testWidgets("puts a sign ending in neither a letter nor a dot against the price", (tester) async {
    await pumpHeader(tester, FiatCurrency.usd);
    expect(gapBetween(tester, r"$", "..."), 0);

    await pumpHeader(tester, FiatCurrency.idr);
    expect(gapBetween(tester, "Rp", "..."), greaterThan(0));

    await pumpHeader(tester, FiatCurrency.eur);
    expect(gapBetween(tester, "...", "€"), greaterThan(0));
  });

  testWidgets("keeps the sign on its English side in a right-to-left UI", (tester) async {
    await pumpHeader(tester, FiatCurrency.usd, direction: TextDirection.rtl);
    expect(gapBetween(tester, r"$", "..."), 0);

    await pumpHeader(tester, FiatCurrency.eur, direction: TextDirection.rtl);
    expect(gapBetween(tester, "...", "€"), greaterThan(0));
  });

  testWidgets("redraws the sign on its side when the currency format changes", (tester) async {
    final showsIsoCode = Observable(false);
    FiatCurrency.showsIsoCode = () => showsIsoCode.value;
    addTearDown(() => FiatCurrency.showsIsoCode = () => false);

    await pumpHeader(tester, FiatCurrency.eur);

    expect(gapBetween(tester, "...", "€"), greaterThan(0));

    runInAction(() => showsIsoCode.value = true);
    await tester.pump();

    expect(find.text("€"), findsNothing);
    expect(gapBetween(tester, "EUR", "..."), greaterThan(0));
  });
}
