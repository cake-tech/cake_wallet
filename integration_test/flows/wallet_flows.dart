import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../robots/new_dashboard_robot.dart";
import "auth_flows.dart";

/// Journeys around the wallet list tab, switching between already created wallets.
class WalletFlows {
  WalletFlows(this.tester)
      : _authFlows = AuthFlows(tester),
        _dashboardRobot = NewDashboardRobot(tester);

  final WidgetTester tester;
  final AuthFlows _authFlows;
  final NewDashboardRobot _dashboardRobot;

  /// Switches to the wallet with the given name from the wallets tab.
  ///
  /// Wallet names are user data so matching on text is stable here, rows on the wallet
  /// list have no per wallet keys.
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
