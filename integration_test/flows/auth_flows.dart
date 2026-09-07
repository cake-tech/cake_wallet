import "package:flutter_test/flutter_test.dart";

import "../core/test_config.dart";
import "../robots/auth_page_robot.dart";

class AuthFlows {
  AuthFlows(this.tester) : _authPageRobot = AuthPageRobot(tester);

  final WidgetTester tester;
  final AuthPageRobot _authPageRobot;

  Future<void> authenticateWithPin({List<int>? pin, bool required = true}) async {
    final prompted = await _waitForPinWidget(
      timeout: required ? const Duration(seconds: 30) : const Duration(seconds: 5),
    );

    if (!prompted) {
      expect(required, false, reason: "The pin was never asked for");

      return;
    }

    await _authPageRobot.enterPinCode(pin ?? TestConfig.pin);
  }

  bool isPinWidgetShown() => _authPageRobot.onAuthPage();

  Future<bool> _waitForPinWidget({Duration timeout = const Duration(seconds: 30)}) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (_authPageRobot.onAuthPage()) {
        return true;
      }
    }

    return false;
  }
}
