import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';

class PinCodeWidgetRobot {
  PinCodeWidgetRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  void hasPinCodeWidget() {
    final pinCodeWidget = find.bySubtype<PinCodeWidget>();
    expect(pinCodeWidget, findsOneWidget);
  }

  void hasNumberButtonsVisible() {
    // Confirmation for buttons 1-9
    for (var i = 1; i < 10; i++) {
      commonTestCases.hasValueKey('pin_code_button_${i}_key');
    }

    // Confirmation for 0 button
    commonTestCases.hasValueKey('pin_code_button_0_key');
  }

  Future<void> pushPinButton(int index) async {
    await commonTestCases.tapItemByKey('pin_code_button_${index}_key');
  }

  Future<void> enterPinCode(List<int> pinCode, bool isFirstEntry) async {
    for (int pin in pinCode) {
      await pushPinButton(pin);
    }

    await commonTestCases.defaultSleepTime();
  }
}
