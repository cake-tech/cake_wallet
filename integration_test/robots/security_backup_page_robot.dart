import "package:cake_wallet/src/screens/settings/security_backup_page.dart";

import "../core/base_robot.dart";

class SecurityBackupPageRobot extends BaseRobot {
  SecurityBackupPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<SecurityBackupPage>();
  }

  Future<void> openChangePin() async {
    await tapByKey("security_backup_page_change_pin_button_key");
  }
}
