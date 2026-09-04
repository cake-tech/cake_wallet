import "package:cake_wallet/src/screens/welcome/welcome_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WelcomePageRobot extends BaseRobot {
  WelcomePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WelcomePage>();
  }

  void confirmActionButtonsDisplay() {
    final createNewWalletButton =
        find.byKey(const ValueKey("welcome_page_create_new_wallet_button_key"));

    final restoreWalletButton =
        find.byKey(const ValueKey("welcome_page_restore_wallet_button_key"));

    expect(createNewWalletButton, findsOneWidget);
    expect(restoreWalletButton, findsOneWidget);
  }

  Future<void> navigateToCreateNewWalletPage() async {
    await tapByKey("welcome_page_create_new_wallet_button_key");
  }

  bool hasNewSingleSeedButton() =>
      isKeyPresent("wallet_group_description_page_create_new_seed_button_key");

  Future<void> tapNewSingleSeed() async {
    await tapByKey("wallet_group_description_page_create_new_seed_button_key");
  }

  Future<void> navigateToRestoreWalletPage() async {
    await tapByKey("welcome_page_restore_wallet_button_key");
  }

  Future<void> backAndVerify() async {
    await goBack();
    await isDisplayed();
  }
}
