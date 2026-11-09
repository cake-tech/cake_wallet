import "package:cake_wallet/new-ui/pages/seed/show_keys_disclaimer_page.dart";

import "../core/base_robot.dart";

class ShowKeysDisclaimerPageRobot extends BaseRobot {
  ShowKeysDisclaimerPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<ShowKeysDisclaimerPage>();
  }

  Future<void> tapShowKeys() async {
    await tapByKey("show_keys_disclaimer_page_button_key");
  }
}
