import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/src/screens/settings/display_settings_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";
import "fiat_currency_picker_robot.dart";

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

  Future<void> chooseFiatCurrency(FiatCurrency currency) =>
      FiatCurrencyPickerRobot(tester).choose(currency);

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
