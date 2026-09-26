import "package:cake_wallet/new-ui/pages/settings_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class NewSettingsPageRobot extends BaseRobot {
  NewSettingsPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(SettingsMainPage));
  }

  Future<void> openRow(String route) async {
    await scrollUntilRowVisible(route);
    await tapByKey(route);
  }

  Future<void> scrollUntilRowVisible(String route) async {
    final rowFinder = find.byKey(ValueKey(route));

    if (tester.any(rowFinder)) {
      return;
    }

    final scrollableFinder = find.descendant(
      of: find.byType(SettingsMainPage),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      rowFinder,
      200,
      scrollable: scrollableFinder.first,
      maxScrolls: 30,
    );

    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> confirmLeafPageDisplayed(Type pageType) async {
    await pumpUntilFound(find.byType(pageType));
  }
}
