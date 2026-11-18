import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_row.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class FiatCurrencyPickerRobot extends BaseRobot {
  FiatCurrencyPickerRobot(super.tester);

  @override
  Future<void> isDisplayed() => pumpUntilFound(find.byType(FiatCurrencyPickerSheet));

  Future<void> choose(FiatCurrency currency) async {
    final search = find.descendant(
      of: find.byType(CurrencyPickerSearchField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(search, currency.fullName);
    final row = find.byWidgetPredicate(
      (widget) => widget is FiatCurrencyRow && widget.currency == currency,
    );
    await tapWhenVisible(row);
    await pumpUntilGone(find.byType(FiatCurrencyPickerSheet));
  }
}
