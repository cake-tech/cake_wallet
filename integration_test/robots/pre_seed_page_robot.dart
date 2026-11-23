import "package:cake_wallet/new-ui/pages/seed/pre_seed_page.dart";

import "../core/base_robot.dart";

class PreSeedPageRobot extends BaseRobot {
  PreSeedPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<PreSeedPage>();
  }

  // The button is only built once all three boxes are ticked
  Future<void> onConfirmButtonPressed() async {
    await tapByKey("pre_seed_page_only_way_checkbox_key");
    await tapByKey("pre_seed_page_write_down_checkbox_key");
    await tapByKey("pre_seed_page_never_share_checkbox_key");
    await tapByKey("pre_seed_page_button_key");
  }
}
