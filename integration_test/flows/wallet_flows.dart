import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
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

  Future<void> switchToWallet(String name) async {
    await _dashboardRobot.openWalletsTab();

    final walletFinder = find.text(name);

    await _dashboardRobot.pumpUntilFound(walletFinder);

    await tester.tap(walletFinder.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // Switching re-authenticates unless the pin timeout window is still open.
    await _authFlows.authenticateWithPinIfPrompted();

    // The row does nothing at all when that wallet is already the open one, and the load
    // itself runs behind a progress overlay, so the store is the only thing that tells us
    // the switch happened rather than the tap having quietly gone nowhere.
    final switched = await _dashboardRobot.pumpUntil(
      () => getIt.get<AppStore>().wallet?.name == name,
      timeout: const Duration(minutes: 2),
    );

    expect(switched, true, reason: "Wallet never became $name after tapping its row");
  }
}
