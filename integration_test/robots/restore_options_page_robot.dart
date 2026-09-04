import "package:cake_wallet/src/screens/restore/restore_options_page.dart";

import "../core/base_robot.dart";

class RestoreOptionsPageRobot extends BaseRobot {
  RestoreOptionsPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<RestoreOptionsPage>();
  }

  void hasRestoreOptionsButton() {
    hasValueKey("restore_options_from_seeds_or_keys_button_key");
    hasValueKey("restore_options_from_backup_button_key");
    hasValueKey("restore_options_from_hardware_wallet_button_key");
    hasValueKey("restore_options_from_qr_button_key");
  }

  Future<void> navigateToRestoreFromSeedsOrKeysPage() async {
    await tapByKey("restore_options_from_seeds_or_keys_button_key");
  }

  Future<void> navigateToRestoreFromBackupPage() async {
    await tapByKey("restore_options_from_backup_button_key");
  }

  Future<void> navigateToRestoreFromHardwareWalletPage() async {
    await tapByKey("restore_options_from_hardware_wallet_button_key");
  }

  Future<void> backAndVerify() async {
    await goBack();
    await isDisplayed();
  }
}
