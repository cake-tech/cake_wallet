import "package:cake_wallet/src/screens/restore/restore_options_page.dart";

import "../core/base_robot.dart";

class RestoreOptionsPageRobot extends BaseRobot {
  RestoreOptionsPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<RestoreOptionsPage>();
  }

  Future<void> navigateToRestoreFromSeedsOrKeysPage() async {
    await tapByKey("restore_options_from_seeds_or_keys_button_key");
  }
}
