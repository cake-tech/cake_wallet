import "package:cake_wallet/src/screens/new_wallet/wallet_group_existing_seed_description_page.dart";

import "../core/base_robot.dart";

class WalletGroupExistingSeedPageRobot extends BaseRobot {
  WalletGroupExistingSeedPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<WalletGroupExistingSeedDescriptionPage>();
  }

  Future<void> openWallet() async {
    await tapByKey("wallet_group_existing_seed_description_page_open_wallet_button_key");
  }
}
