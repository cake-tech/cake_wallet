import "package:cake_wallet/di.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:flutter/material.dart";
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

  Future<void> _expandWalletGroups({int maxGroups = 10}) async {
    for (int index = 0; index < maxGroups; index++) {
      final tile = find.byKey(ValueKey("group_wallets_expansion_tile_widget_$index"));

      if (!tester.any(tile)) {
        return;
      }

      await tester.tap(tile.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> switchToWallet(String name) async {
    await _dashboardRobot.openWalletsTab();

    // A group can carry the same name as one of its wallets (single-wallet groups are named
    // after their wallet), so always open the groups and tap the wallet row, not the header.
    await _expandWalletGroups();

    final walletFinder = find.text(name);
    await _dashboardRobot.pumpUntilFound(walletFinder);

    // The wallet row comes after its group's header in the list.
    await tester.tap(walletFinder.last, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    await _authFlows.authenticateWithPin(required: false);

    final switched = await _dashboardRobot.pumpUntil(
          () => getIt.get<AppStore>().wallet?.name == name,
      timeout: const Duration(minutes: 2),
    );

    expect(switched, true, reason: "Wallet never became $name after tapping its row");
  }
}
