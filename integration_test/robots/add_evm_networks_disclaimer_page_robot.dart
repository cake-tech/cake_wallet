import "package:cake_wallet/new-ui/pages/wallet_network/add_evm_networks_disclaimer_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class AddEvmNetworksDisclaimerPageRobot extends BaseRobot {
  AddEvmNetworksDisclaimerPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<AddEvmNetworksDisclaimerPage>();
  }

  bool get isShowing => tester.any(find.byType(AddEvmNetworksDisclaimerPage));

  Future<void> tapCancel() async {
    await tapByKey("add_evm_networks_disclaimer_cancel_button_key");

    await pumpUntilGone(find.byType(AddEvmNetworksDisclaimerPage));
  }

  Future<void> tapContinue() async {
    await tapByKey("add_evm_networks_disclaimer_continue_button_key");

    await pumpUntilGone(find.byType(AddEvmNetworksDisclaimerPage));
  }
}
