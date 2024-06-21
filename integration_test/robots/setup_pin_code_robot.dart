import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/components/common_checks.dart';

class SetupPinCodeRobot {
  SetupPinCodeRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isSetupPinCodePage() async {
    await commonTestCases.isSpecificPage<SetupPinCodePage>();
  }

  void hasPinCodeWidget() {
    final pinCodeWidget = find.byType(PinCodeWidget);
    expect(pinCodeWidget, findsOneWidget);
  }

  void hasTitle() {
    commonTestCases.hasText(S.current.setup_pin);
  }

  void hasNumberButtonsVisible() {
    // Confirmation for buttons 1-9
    for (var i = 1; i < 10; i++) {
      commonTestCases.hasKey('pin_code_button_${i}_key');
    }

    // Confirmation for 0 button
    commonTestCases.hasKey('pin_code_button_0_key');
  }

  Future<void> pushPinButton(int index) async {
    final button = find.byKey(ValueKey('pin_code_button_${index}_key'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    commonTestCases.defaultSleepTime();
  }

  Future<void> enterPinCode() async {
    final PinCodeState pinCodeState = tester.state(find.byType(PinCodeWidget));
    print(pinCodeState.pin);
    final codeToUse = [0, 8, 0, 1];
    await codeToUse.map((code) async {
      await pushPinButton(code);
    });

    commonTestCases.defaultSleepTime();
    expect(pinCodeState.pin, '0801');
  }
}
