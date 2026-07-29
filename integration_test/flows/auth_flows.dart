import "package:flutter_test/flutter_test.dart";

import "../core/test_config.dart";
import "../robots/auth_page_robot.dart";

/// Drives the pin authentication gate that protects sensitive routes.
class AuthFlows {
  AuthFlows(this.tester) : _authPageRobot = AuthPageRobot(tester);

  final WidgetTester tester;
  final AuthPageRobot _authPageRobot;

  Future<void> authenticateWithPin({List<int>? pin}) async {
    await _waitForPinWidget();

    await _authPageRobot.enterPinCode(pin ?? TestConfig.pin);
  }

  /// Enters the pin only when the gate actually shows, auth is skipped inside the pin
  /// timeout window so the prompt is not guaranteed.
  Future<void> authenticateWithPinIfPrompted({List<int>? pin}) async {
    final prompted = await _waitForPinWidget(timeout: const Duration(seconds: 5));

    if (!prompted) {
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
