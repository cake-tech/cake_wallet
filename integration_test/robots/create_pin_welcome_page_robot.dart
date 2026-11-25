import "package:cake_wallet/src/screens/welcome/create_pin_welcome_page.dart";

import "../core/base_robot.dart";

class CreatePinWelcomePageRobot extends BaseRobot {
  CreatePinWelcomePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<CreatePinWelcomePage>();
  }

  Future<void> tapSetAPinButton() async {
    await tapByKey("create_pin_welcome_page_create_a_pin_button_key");
  }
}
