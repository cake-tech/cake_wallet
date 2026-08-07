import "package:cake_wallet/new-ui/pages/home_page.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/pulsing_dot.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class HomePageRobot extends BaseRobot {
  HomePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byKey(const ValueKey("home_page_wallet_name_text_key")));
  }

  Future<void> hasWalletName(String name) async {
    await pumpUntilFound(find.byKey(const ValueKey("home_page_wallet_name_text_key")));

    expect(textByKey("home_page_wallet_name_text_key"), name);
  }

  Future<void> openSendSheet() async {
    await tapByKey("home_page_send_button_key");
  }

  Future<void> openReceiveSheet() async {
    await tapByKey("home_page_receive_button_key");
  }

  Future<void> openSwapSheet() async {
    await tapByKey("home_page_swap_button_key");
  }

  Future<void> openSettingsSheet() async {
    await tapByKey("home_page_settings_button_key");
  }

  Future<void> openHistoryTab() async {
    final tabFinder = find.byKey(const ValueKey("line_tab_switcher_1_key"));

    if (!tester.any(tabFinder)) {
      return;
    }

    await tapWhenVisible(tabFinder);

    await settle();
  }

  Future<void> confirmTransactionHistoryVisible({
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final hasTransactions = await pumpUntil(
      () => _dashboardTransactionCount() > 0,
      timeout: timeout,
    );

    expect(
      hasTransactions,
      true,
      reason: "No transactions arrived within ${timeout.inSeconds}s",
    );

    await openHistoryTab();

    await pumpUntilFound(find.byType(HistoryTile));

    expect(
      tester.widgetList(find.byType(HistoryTile)).length,
      lessThanOrEqualTo(3),
      reason: "The home page preview should never render more than the short history",
    );
  }

  Future<void> openAllTransactions() async {
    final actionButton = find.byKey(const ValueKey("assets_history_action_button_key"));
    final historyBar = find.byKey(const ValueKey("history_top_bar_key"));

    await tapWhenVisible(tester.any(actionButton) ? actionButton : historyBar);

    await pumpUntilFound(find.byKey(const ValueKey("history_modal_key")));
  }

  Future<void> confirmAllTransactionsVisible() async {
    await pumpUntilFound(find.byType(HistoryTile));

    final rendered = tester.widgetList(find.byType(HistoryTile)).length;

    if (_dashboardTransactionCount() > 3) {
      expect(
        rendered,
        greaterThan(3),
        reason: "The All view rendered $rendered tiles, no more than the home preview does",
      );

      return;
    }

    expect(find.byType(HistoryTile), findsWidgets);
  }

  Future<void> confirmSyncIndicatorShown(Type statusType) async {
    final shown = await pumpUntil(
      () => tester.any(find.byType(PulsingDot)) || tester.any(find.byKey(ValueKey(statusType))),
    );

    expect(
      shown,
      true,
      reason: "Sync bar showed nothing while the wallet reported $statusType",
    );
  }

  int _dashboardTransactionCount() {
    final finder = find.byType(NewHomePage);

    if (!tester.any(finder)) {
      return 0;
    }

    return tester.widget<NewHomePage>(finder.first).dashboardViewModel.transactions.length;
  }
}
