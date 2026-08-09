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

  // The language row is always there. The currency row next to it is only built when the
  // fiat api mode is on, so it cannot be reached without turning that on first.
  Future<void> openLanguagePicker() async {
    await tapByKey("display_settings_language");
  }

  // The picker is keyed on the item itself, which for languages is the code rather than the
  // name shown on screen.
  Future<void> chooseLanguage(String code) async {
    await tapByKey("picker_items_index_${code}_button_key");

    await settle();
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
