import "package:cake_wallet/src/screens/new_wallet/new_wallet_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class NewWalletPageRobot extends BaseRobot {
  NewWalletPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<NewWalletPage>();
  }

  Future<void> enterWalletName(String walletName) async {
    await enterTextByKey("new_wallet_page_wallet_name_textformfield_key", walletName);
  }

  Future<void> generateWalletName() async {
    await tapByKey("new_wallet_page_wallet_name_textformfield_generate_name_button_key");
  }

  Future<void> expectNameRejected() async {
    await pumpUntilFound(find.byType(AlertWithOneAction));

    hasType<NewWalletPage>();
  }

  Future<void> onNextButtonPressed() async {
    await tapByKey("new_wallet_page_confirm_button_key");
  }
}
