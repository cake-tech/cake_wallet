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

  Future<void> enterPinCode(List<int> pinCode) async {
    for (final pin in pinCode) {
      await tapByKey("pin_code_button_${pin}_key");
    }

    await settle();
  }
}
