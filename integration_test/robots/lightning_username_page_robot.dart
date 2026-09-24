import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class LightningUsernamePageRobot extends BaseRobot {
  LightningUsernamePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byKey(const ValueKey("lightning_username_page_skip_button_key")));
  }

  Future<void> tapSkip() async {
    await tapByKey("lightning_username_page_skip_button_key");
  }
}
