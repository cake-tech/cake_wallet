import "package:cake_wallet/src/screens/pin_code/pin_code_widget.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class PinCodeWidgetRobot extends BaseRobot {
  PinCodeWidgetRobot(super.tester);

  @override
  Future<void> isDisplayed() async => hasPinCodeWidget();

  void hasPinCodeWidget() {
    final pinCodeWidget = find.bySubtype<PinCodeWidget>();
    expect(pinCodeWidget, findsOneWidget);
  }

  void hasNumberButtonsVisible() {
    for (var i = 1; i < 10; i++) {
      hasValueKey("pin_code_button_${i}_key");
    }
    hasValueKey("pin_code_button_0_key");
  }

  Future<void> enterPassword(String password) async {
    await enterTextByKey("enter_wallet_password", password);
    await settle();

    await tapByKey("unlock");
    await settle();
  }

  Future<void> enterPinCode(List<int> pinCode) async {
    for (final pin in pinCode) {
      await tapByKey("pin_code_button_${pin}_key");
    }

    // The last digit sends the gate away on its own. Returning while that route is still
    // popping lands the caller's next navigation on a locked navigator.
    await settle();
  }
}
