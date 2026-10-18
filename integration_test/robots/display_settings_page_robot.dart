import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_row.dart";
import "package:cake_wallet/src/screens/settings/display_settings_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class DisplaySettingsPageRobot extends BaseRobot {
  DisplaySettingsPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<DisplaySettingsPage>();
  }

  Future<void> openLanguagePicker() async {
    await tapByKey("display_settings_language");
  }

  Future<void> chooseLanguage(String code) async {
    await tapByKey("picker_items_index_${code}_button_key");

    await settle();
  }

  bool hasFiatCurrencyRow() =>
      tester.any(find.byKey(const ValueKey("display_settings_fiat_currency")));

  Future<void> openFiatCurrencyPicker() async {
    await tapByKey("display_settings_fiat_currency");

    await pumpUntilFound(find.byType(FiatCurrencyPickerSheet));
  }

  Future<void> chooseFiatCurrency(FiatCurrency currency) async {
    final searchField = find.descendant(
      of: find.byType(CurrencyPickerSearchField),
      matching: find.byType(TextFormField),
    );

    await tester.enterText(searchField, currency.fullName);

    final row = find.byWidgetPredicate(
      (widget) => widget is FiatCurrencyRow && widget.currency == currency,
    );

    await pumpUntilFound(row);

    await tester.tap(row.first);

    await pumpUntilGone(find.byType(FiatCurrencyPickerSheet));
  }

  void expectFiatCurrencyShown(FiatCurrency currency) {
    expect(
      find.descendant(
        of: find.byKey(const ValueKey("display_settings_fiat_currency")),
        matching: find.text(currency.title),
      ),
      findsOneWidget,
      reason: "The currency row still does not show ${currency.title}",
    );
  }

  void expectLanguageShown(String displayName) {
    expect(
      find.descendant(
        of: find.byKey(const ValueKey("display_settings_language")),
        matching: find.text(displayName),
      ),
      findsOneWidget,
      reason: "The language row still does not show $displayName",
    );
  }
}
