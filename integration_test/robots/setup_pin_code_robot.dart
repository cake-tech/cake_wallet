import "package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart";

import "pin_code_widget_robot.dart";

class SetupPinCodeRobot extends PinCodeWidgetRobot {
  SetupPinCodeRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<SetupPinCodePage>();
  }

  Future<void> tapSuccessButton() async {
    await tapByKey("setup_pin_code_success_button_key");
  }
}
