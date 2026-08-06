import "package:cake_wallet/new-ui/pages/home_page.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart";
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

    // History tiles live in a lazy sliver further down the home scroll view.
    final scrollableFinder = find.descendant(
      of: find.byType(NewHomePage),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.byType(HistoryTile),
      300,
      scrollable: scrollableFinder.first,
      maxScrolls: 30,
    );

    expect(find.byType(HistoryTile), findsWidgets);
  }

  int _dashboardTransactionCount() {
    final finder = find.byType(NewHomePage);

    if (!tester.any(finder)) {
      return 0;
    }

    return tester.widget<NewHomePage>(finder.first).dashboardViewModel.transactions.length;
  }
}
