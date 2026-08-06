import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/welcome/create_pin_welcome_page.dart";
import "package:cake_wallet/wallet_type_utils.dart";

import "../core/base_robot.dart";

class CreatePinWelcomePageRobot extends BaseRobot {
  CreatePinWelcomePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<CreatePinWelcomePage>();
  }

  void hasTitle() {
    String title;
    if (isMoneroOnly) {
      title = S.current.monero_com;
    }

    title = S.current.cake_wallet;

    hasText(title);
  }

  void hasDescription() {
    String description;
    if (isMoneroOnly) {
      description = S.current.monero_com_wallet_text;
    }

    description = S.current.new_first_wallet_text;

    hasText(description);
  }

  Future<void> tapSetAPinButton() async {
    await tapByKey("create_pin_welcome_page_create_a_pin_button_key");
  }
}
