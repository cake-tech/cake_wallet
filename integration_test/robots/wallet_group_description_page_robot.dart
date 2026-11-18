import "package:cake_wallet/src/screens/new_wallet/wallet_group_description_page.dart";

import "../core/base_robot.dart";

class WalletGroupDescriptionPageRobot extends BaseRobot {
  WalletGroupDescriptionPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletGroupDescriptionPage>();
  }

  bool hasNewSingleSeedButton() =>
      isKeyPresent("wallet_group_description_page_create_new_seed_button_key");

  Future<void> navigateToCreateNewSeedPage() async {
    if (hasNewSingleSeedButton()) {
      await tapByKey("wallet_group_description_page_create_new_seed_button_key");
    }
  }

  Future<void> navigateToChooseWalletGroup() async {
    await tapByKey("wallet_group_description_page_choose_wallet_group_button_key");
  }
}
