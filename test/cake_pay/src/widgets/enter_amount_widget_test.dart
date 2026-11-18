import "package:cake_wallet/cake_pay/src/widgets/enter_amount_widget.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("shows the sign in front of the typed amount for every currency", (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final gaps = <double>{};
    for (final direction in TextDirection.values) {
      for (final currency in [FiatCurrency.usd, FiatCurrency.eur, FiatCurrency.idr]) {
        final controller = TextEditingController(text: "12.34");
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: S.delegate.supportedLocales,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: EnterAmountWidget(
                  minValue: "5",
                  maxValue: "100",
                  fiatCurrency: currency,
                  amountFieldFocus: focusNode,
                  amountController: controller,
                  onAmountChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        final signRight = tester.getTopRight(find.text(currency.signAsPrefix)).dx;
        final amountLeft = tester.getTopLeft(find.byType(EditableText)).dx;

        expect(
          amountLeft,
          greaterThanOrEqualTo(signRight),
          reason: "${currency.title}, $direction",
        );
        gaps.add(amountLeft - signRight);
      }
    }

    expect(gaps, hasLength(1));
  });
}
