import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

/// Drives the home tab of the new UI dashboard.
class HomePageRobot extends BaseRobot {
  HomePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    // The wallet name bar only renders while the home tab is the visible one.
    await pumpUntilFound(find.byKey(const ValueKey("home_page_wallet_name_text_key")));
  }

  Future<void> hasWalletName(String name) async {
    await pumpUntilFound(find.byKey(const ValueKey("home_page_wallet_name_text_key")));

    expect(textByKey("home_page_wallet_name_text_key"), name);
  }

  Future<void> openSendSheet() async {
    await tapByKey("home_page_send_button_key");
  }

  Future<void> openReceiveSheet() async {
    await tapByKey("home_page_receive_button_key");
  }

  Future<void> openSwapSheet() async {
    await tapByKey("home_page_swap_button_key");
  }

  Future<void> openSettingsSheet() async {
    await tapByKey("home_page_settings_button_key");
  }
}
