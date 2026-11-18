import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/floating_amount_input.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("puts a sign ending in neither a letter nor a dot against the amount",
      (tester) async {
    Future<double> gapAfterSign(
      FiatCurrency currency, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      final controller = TextEditingController(text: "12");
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: FloatingAmountInput(currency: currency, controller: controller),
            ),
          ),
        ),
      );

      return tester.getTopLeft(find.byType(EditableText)).dx -
          tester.getTopRight(find.text(currency.sign)).dx;
    }

    expect(await gapAfterSign(FiatCurrency.usd), 0);
    expect(await gapAfterSign(FiatCurrency.idr), greaterThan(0));
    expect(await gapAfterSign(FiatCurrency.usd, direction: TextDirection.rtl), 0);
  });

  testWidgets("puts a sign that goes after the number behind the amount", (tester) async {
    for (final direction in TextDirection.values) {
      final controller = TextEditingController(text: "12");
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: FloatingAmountInput(currency: FiatCurrency.eur, controller: controller),
            ),
          ),
        ),
      );

      final gap =
          tester.getTopLeft(find.text("€")).dx - tester.getTopRight(find.byType(EditableText)).dx;

      expect(gap, greaterThan(0), reason: "$direction");
    }
  });
}
