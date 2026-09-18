import "package:cake_wallet/new-ui/pages/home_page.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_tile.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/transaction_details_modal.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

class HomePageRobot extends BaseRobot {
  HomePageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    final shown = await pumpUntil(() => isInFront);

    expect(shown, true, reason: "The home tab never came to the front");
  }

  bool get isInFront {
    final stackFinder = find.byType(IndexedStack);

    if (!tester.any(stackFinder)) {
      return false;
    }

    final stack = tester.widget<IndexedStack>(stackFinder.first);
    final index = stack.children.indexWhere((child) => child is NewHomePage);

    return index >= 0 && stack.index == index;
  }

  Future<void> hasWalletName(String name) async {
    final nameFinder = find.byKey(const ValueKey("home_page_wallet_name_text_key"));
    final syncBarFinder = find.byType(SyncBar);

    final shown = await pumpUntil(() => tester.any(nameFinder) || tester.any(syncBarFinder));

    expect(shown, true, reason: "Top bar showed neither the wallet name nor the sync bar");

    if (!tester.any(nameFinder)) {
      tester.printToConsole("Sync bar is in place of the wallet name, not checking it on screen");
      return;
    }

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
    await pumpUntilFound(_allViewTiles);

    final rendered = tester.widgetList(_allViewTiles).length;

    if (_dashboardTransactionCount() > 3) {
      expect(
        rendered,
        greaterThan(3),
        reason: "The All view rendered $rendered tiles, no more than the home preview does",
      );

      return;
    }

    expect(_allViewTiles, findsWidgets);
  }

  String firstTransactionIdInAllView() {
    final tile = tester.widgetList<HistoryTile>(_allViewTiles).first;
    final key = tile.key! as ValueKey<String>;

    return key.value.substring("home_page_transaction_".length, key.value.length - "_key".length);
  }

  Future<void> openFirstTransactionDetails() async {
    await pumpUntilFound(_allViewTiles);

    await tester.tap(_allViewTiles.first);

    await pumpUntilFound(find.byType(TransactionDetailsModal));

    await settle();
  }

  String openedTransactionId() {
    final modal = tester.widget<TransactionDetailsModal>(find.byType(TransactionDetailsModal));

    return modal.transactionDetailsViewModel.transactionInfo.id;
  }

  void hasTransactionIdRow() {
    expect(
      find.byKey(const ValueKey("standard_list_item_transaction_details_id_key")),
      findsOneWidget,
      reason: "The details opened without showing the transaction id",
    );
  }

  // The home preview stays mounted underneath the modal, so its tiles have to be left out.
  Finder get _allViewTiles => find.descendant(
        of: find.byKey(const ValueKey("history_modal_key")),
        matching: find.byType(HistoryTile),
      );

  Future<void> confirmSyncIndicatorShown() async {
    final syncBar = find.byType(SyncBar);
    final dot = find.descendant(of: syncBar, matching: find.byType(CupertinoActivityIndicator));
    final tick = find.descendant(of: syncBar, matching: find.byIcon(Icons.check));

    SyncStatus? lastStatus;
    bool? syncedFromTheStart;

    final shown = await pumpUntil(() {
      lastStatus = _dashboardStatus();

      if (lastStatus == null) {
        return false;
      }

      final synced = lastStatus.runtimeType == SyncedSyncStatus;
      syncedFromTheStart ??= synced;

      if (!synced) {
        final reported =
            find.descendant(of: syncBar, matching: find.byKey(ValueKey(lastStatus.runtimeType)));

        return tester.any(reported);
      }

      return tester.any(tick) || (syncedFromTheStart! && !tester.any(dot));
    });

    if (syncedFromTheStart == true) {
      tester.printToConsole("Already synced when checked, the sync bar itself was not observed");
    }

    expect(
      shown,
      true,
      reason: "Sync bar showed nothing while the wallet reported ${lastStatus.runtimeType}",
    );
  }

  SyncStatus? _dashboardStatus() {
    final finder = find.byType(NewHomePage);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<NewHomePage>(finder.first).dashboardViewModel.status;
  }

  int _dashboardTransactionCount() {
    final finder = find.byType(NewHomePage);

    if (!tester.any(finder)) {
      return 0;
    }

    return tester.widget<NewHomePage>(finder.first).dashboardViewModel.transactions.length;
  }
}
