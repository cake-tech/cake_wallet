import "package:cake_wallet/src/screens/disclaimer/disclaimer_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class DisclaimerPageRobot extends BaseRobot {
  DisclaimerPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<DisclaimerPage>();
  }

  void hasCheckIcon({required bool hasBeenTapped}) {
    final checkIcon = find.byKey(const ValueKey("disclaimer_check_icon_key"));
    expect(checkIcon, hasBeenTapped ? findsOneWidget : findsNothing);
  }

  void hasDisclaimerCheckbox() {
    final checkBox = find.byKey(const ValueKey("disclaimer_check_key"));
    expect(checkBox, findsOneWidget);
  }

  Future<void> tapDisclaimerCheckbox() async {
    await tapByKey("disclaimer_check_key");
  }

  Future<void> tapAcceptButton() async {
    await tapByKey("disclaimer_accept_button_key");
  }
}
