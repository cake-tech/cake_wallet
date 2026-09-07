import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/auth/auth_page.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

import "pin_code_widget_robot.dart";

class AuthPageRobot extends PinCodeWidgetRobot {
  AuthPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await isSpecificPage<AuthPage>();
  }

  bool onAuthPage() {
    final hasPinButtons = find.byKey(const ValueKey("pin_code_button_3_key"));
    final hasPin = hasPinButtons.tryEvaluate();
    return hasPin;
  }

  bool onAuthPageDesktop() {
    final hasWalletPasswordInput = find.byKey(const ValueKey("enter_wallet_password"));
    return hasWalletPasswordInput.tryEvaluate();
  }

  void hasTitle() {
    hasText(S.current.setup_pin);
  }
}
