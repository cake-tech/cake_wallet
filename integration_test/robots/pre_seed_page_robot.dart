import "package:cake_wallet/src/screens/seed/pre_seed_page.dart";

import "../core/base_robot.dart";

class PreSeedPageRobot extends BaseRobot {
  PreSeedPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<PreSeedPage>();
  }

  Future<void> onConfirmButtonPressed() async {
    await tapByKey("pre_seed_page_button_key");
  }
}
