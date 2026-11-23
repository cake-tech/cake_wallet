import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_row.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("finds a currency by its symbol", (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: FiatCurrencyPickerSheet(selected: FiatCurrency.usd, onSelected: (_) {}),
        ),
      ),
    );

    Future<List<FiatCurrency>> resultsFor(String query) async {
      await tester.enterText(find.byType(TextFormField), query);
      await tester.pump();

      return tester
          .widgetList<FiatCurrencyRow>(find.byType(FiatCurrencyRow))
          .map((row) => row.currency)
          .toList();
    }

    expect(await resultsFor("€"), [FiatCurrency.eur]);
    expect(await resultsFor(r"NT$"), [FiatCurrency.twd]);
    expect(await resultsFor("cn¥"), [FiatCurrency.cny]);
    expect(
      await resultsFor(r"$"),
      containsAll([FiatCurrency.usd, FiatCurrency.cad, FiatCurrency.ars, FiatCurrency.hkd]),
    );
  });
}
