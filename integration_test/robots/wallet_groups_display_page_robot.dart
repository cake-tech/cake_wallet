import "package:cake_wallet/src/screens/new_wallet/wallet_group_display_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class WalletGroupsDisplayPageRobot extends BaseRobot {
  WalletGroupsDisplayPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletGroupsDisplayPage>();
  }

  Future<void> selectWallet(String name) async {
    await tapWhenVisible(find.text(name));
  }

  Future<void> continueWithSelectedSeed() async {
    await tapByKey("wallet_group_display_page_next_button_key");
  }
}
