import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

/// Drives the new UI dashboard shell, the navbar and its tab switching.
class NewDashboardRobot extends BaseRobot {
  NewDashboardRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byKey(const ValueKey("new_dashboard_page_key")));
  }

  Future<void> openHomeTab() async {
    await tapByKey("dashboard_page_home_action_button_key");
  }

  Future<void> openWalletsTab() async {
    await tapByKey("dashboard_page_wallets_action_button_key");
  }

  Future<void> openContactsTab() async {
    await tapByKey("dashboard_page_contacts_action_button_key");
  }
}
