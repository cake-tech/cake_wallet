import "package:flutter_test/flutter_test.dart";

import "../robots/new_dashboard_robot.dart";
import "auth_flows.dart";

class WalletFlows {
  WalletFlows(this.tester)
      : _authFlows = AuthFlows(tester),
        _dashboardRobot = NewDashboardRobot(tester);

  final WidgetTester tester;
  final AuthFlows _authFlows;
  final NewDashboardRobot _dashboardRobot;

  // Rows on the wallet list have no per wallet keys, and a wallet name is our own test
  // data rather than a translated string, so matching on it is stable.
  Future<void> switchToWallet(String name) async {
    await _dashboardRobot.openWalletsTab();

    final walletFinder = find.text(name);

    await _dashboardRobot.pumpUntilFound(walletFinder);

    await tester.tap(walletFinder.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // Switching re-authenticates unless the pin timeout window is still open.
    await _authFlows.authenticateWithPinIfPrompted();
  }
}
