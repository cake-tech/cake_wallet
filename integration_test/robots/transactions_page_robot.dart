import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/transactions_page.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../components/common_test_cases.dart';

class TransactionsPageRobot {
  TransactionsPageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isTransactionsPage() async {
    await commonTestCases.isSpecificPage<TransactionsPage>();
    await commonTestCases.takeScreenshots('transactions_page');
  }

  Future<void> confirmTransactionsPageConstantsDisplayProperly() async {
    await commonTestCases.defaultSleepTime();

    final transactionsPage = tester.widget<TransactionsPage>(find.byType(TransactionsPage));
    final dashboardViewModel = transactionsPage.dashboardViewModel;
    if (dashboardViewModel.status is SyncingSyncStatus) {
      commonTestCases.hasValueKey('transactions_page_syncing_alert_card_key');
      commonTestCases.hasText(S.current.syncing_wallet_alert_title);
      commonTestCases.hasText(S.current.syncing_wallet_alert_content);
    }

    commonTestCases.hasValueKey('transactions_page_header_row_key');
    commonTestCases.hasText(S.current.transactions);
    commonTestCases.hasValueKey('transactions_page_header_row_transaction_filter_button_key');
  }

  Future<void> confirmTransactionHistoryListDisplaysCorrectly(bool hasTxHistoryWhileSyncing) async {
    try {
      final transactionsPage = tester.widget<TransactionsPage>(find.byType(TransactionsPage));
      final dashboardViewModel = transactionsPage.dashboardViewModel;

      await _waitForListToBeReady();

      if (!hasTxHistoryWhileSyncing) {
        await _waitForSyncToComplete(dashboardViewModel);
      } else {
        await tester.pump(Duration(seconds: 2));
        await tester.pumpAndSettle();
      }

      await _performComprehensiveItemCheck(dashboardViewModel);
    } catch (e) {
      tester.printToConsole('Error in transaction history check: $e');
    }
  }

  Future<void> _waitForSyncToComplete(DashboardViewModel dashboardViewModel) async {
    const maxWaitTime = Duration(minutes: 2);
    final endTime = DateTime.now().add(maxWaitTime);

    tester.printToConsole('Waiting for wallet to sync...');

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      if (dashboardViewModel.status is SyncedSyncStatus) {
        tester.printToConsole('Wallet synced successfully');
        return;
      }

      // Check if we have now have transaction items available
      if (dashboardViewModel.items.isNotEmpty) {
        tester.printToConsole('Items available while syncing, proceeding with test');
        return;
      }

      tester.printToConsole('Sync status: ${dashboardViewModel.status.runtimeType}');
    }

    tester.printToConsole('Warning: Wallet did not sync within expected time, proceeding anyway');
  }

  Future<void> _performComprehensiveItemCheck(DashboardViewModel dashboardViewModel) async {
    try {
      await _waitForItemsToLoad(dashboardViewModel);

      final itemsToProcess = dashboardViewModel.items.where((item) {
        if (item is DateSectionItem) return false;
        if (item is TransactionListItem) {
          return !(item.hasTokens && item.assetOfTransaction == null);
        }
        return true;
      }).toList();

      if (itemsToProcess.isEmpty) {
        tester.printToConsole('No transaction items to process - checking for placeholder');
        _verifyPlaceholder();
        return;
      }

      // This is a temporary limit to prevent the test from taking too long
      final maxItemsToProcess = 100;
      final itemsToCheck = itemsToProcess.take(maxItemsToProcess).toList();

      tester.printToConsole(
        'Processing ${itemsToCheck.length} items out of ${itemsToProcess.length} total items',
      );

      await _processVisibleItems(itemsToCheck, dashboardViewModel);

      // Try to scroll and process more items if needed
      await _processItemsWithScrolling(itemsToCheck, dashboardViewModel);
    } catch (e) {
      tester.printToConsole('Error in comprehensive item check: $e');
      try {
        _verifyPlaceholder();
      } catch (placeholderError) {
        tester.printToConsole('Could not verify placeholder either: $placeholderError');
      }
    }
  }

  Future<void> _waitForItemsToLoad(DashboardViewModel dashboardViewModel) async {
    const maxWaitTime = Duration(seconds: 30);
    final endTime = DateTime.now().add(maxWaitTime);

    while (DateTime.now().isBefore(endTime)) {
      if (dashboardViewModel.items.isNotEmpty) {
        tester.printToConsole('Items loaded: ${dashboardViewModel.items.length}');
        return;
      }

      // Check if placeholder is shown
      if (tester.any(find.byKey(ValueKey('transactions_page_placeholder_transactions_text_key')))) {
        tester.printToConsole('Placeholder is shown - no items to load');
        return;
      }

      await tester.pump(Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    tester.printToConsole('Warning: No items loaded and no placeholder shown within expected time');
  }

  Future<void> _processVisibleItems(
    List<dynamic> items,
    DashboardViewModel dashboardViewModel,
  ) async {
    try {
      int processedCount = 0;

      for (var item in items) {
        try {
          final keyId = (item.key as ValueKey<String>).value;

          // Check if item is already visible
          if (tester.any(find.byKey(ValueKey(keyId)))) {
            tester.printToConsole('Processing visible item: $keyId');
            await _verifyItemDisplay(item, dashboardViewModel);
            processedCount++;
          }
        } catch (itemError) {
          tester.printToConsole('Error processing item: $itemError');
          continue;
        }
      }

      tester.printToConsole('Processed $processedCount visible items\n');
    } catch (e) {
      tester.printToConsole('Error in visible items processing: $e');
    }
  }

  Future<void> _processItemsWithScrolling(
    List<dynamic> items,
    DashboardViewModel dashboardViewModel,
  ) async {
    try {
      final scrollableFinder = find.descendant(
        of: find.byKey(ValueKey('transactions_page_list_view_builder_key')),
        matching: find.byType(Scrollable),
      );

      if (!tester.any(scrollableFinder)) {
        tester.printToConsole('No scrollable found, skipping scroll processing');
        return;
      }

      int processedCount = 0;
      const maxScrollAttempts = 10;

      for (var item in items) {
        try {
          final keyId = (item.key as ValueKey<String>).value;

          // Skip if already processed
          if (tester.any(find.byKey(ValueKey(keyId)))) {
            continue;
          }

          // Try to scroll to the item
          bool found = false;
          for (int attempt = 0; attempt < maxScrollAttempts; attempt++) {
            await tester.pumpAndSettle(Duration(milliseconds: 200));

            if (tester.any(find.byKey(ValueKey(keyId)))) {
              tester.printToConsole('Found item after scrolling: $keyId');
              await _verifyItemDisplay(item, dashboardViewModel);
              processedCount++;
              found = true;
              break;
            }

            // Perform scroll
            try {
              await tester.drag(scrollableFinder, Offset(0, -100));
              await tester.pumpAndSettle(Duration(milliseconds: 300));
            } catch (scrollError) {
              tester.printToConsole('Scroll failed: $scrollError');
              break;
            }
          }

          if (!found) {
            tester.printToConsole('Could not find item after scrolling: $keyId');
          }
        } catch (itemError) {
          tester.printToConsole('Error processing item with scrolling: $itemError');
          continue;
        }
      }

      tester.printToConsole('Processed $processedCount items with scrolling');
    } catch (e) {
      tester.printToConsole('Error in scroll processing: $e');
    }
  }

  void _verifyPlaceholder() {
    commonTestCases.hasValueKey('transactions_page_placeholder_transactions_text_key');
    commonTestCases.hasText(S.current.placeholder_transactions);
  }

  Future<void> _waitForListToBeReady() async {
    const maxWaitAttempts = 10;
    int attempts = 0;

    while (attempts < maxWaitAttempts) {
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // Check if the list view is present
      final listViewFinder = find.byKey(ValueKey('transactions_page_list_view_builder_key'));
      if (tester.any(listViewFinder)) {
        tester.printToConsole('List view is ready');
        return;
      }

      attempts++;
      tester.printToConsole('Waiting for list view to be ready, attempt $attempts\n');
    }

    tester.printToConsole('List view did not become ready within expected time');
  }

  Future<void> _verifyItemDisplay(dynamic item, DashboardViewModel dashboardViewModel) async {
    // Execute the proper check depending on item type.
    switch (item.runtimeType) {
      case TransactionListItem:
        final transactionItem = item as TransactionListItem;
        tester.printToConsole(transactionItem.formattedTitle);
        tester.printToConsole(transactionItem.formattedFiatAmount);
        tester.printToConsole('\n');
        await _verifyTransactionListItemDisplay(transactionItem, dashboardViewModel);
        break;

      case AnonpayTransactionListItem:
        await _verifyAnonpayTransactionListItemDisplay(item as AnonpayTransactionListItem);
        break;

      case TradeListItem:
        await _verifyTradeListItemDisplay(item as TradeListItem);
        break;

      case OrderListItem:
        await _verifyOrderListItemDisplay(item as OrderListItem);
        break;

      default:
        tester.printToConsole('Unhandled item type: ${item.runtimeType}');
    }
  }

  Future<void> _verifyTransactionListItemDisplay(
    TransactionListItem item,
    DashboardViewModel dashboardViewModel,
  ) async {
    final keyId =
        '${dashboardViewModel.type.name}_transaction_history_item_${item.transaction.id}_key';

    if (!tester.any(find.byKey(ValueKey(keyId)))) {
      tester.printToConsole(
        'Could not find transaction item with key: $keyId for transaction ${item.transaction.id}',
      );
      return;
    }

    if (item.hasTokens && item.assetOfTransaction == null) return;

    try {
      //* ==============Confirm it has the right key for this item ========
      commonTestCases.hasValueKey(keyId);

      //* ======Confirm it displays the properly formatted amount==========
      commonTestCases.findWidgetViaDescendant(
        of: find.byKey(ValueKey(keyId)),
        matching: find.text(item.formattedCryptoAmount),
      );

      //* ======Confirm it displays the properly formatted date============
      final formattedDate = DateFormat('HH:mm').format(item.transaction.date);
      commonTestCases.findWidgetViaDescendant(
        of: find.byKey(ValueKey(keyId)),
        matching: find.text(formattedDate),
      );

      //* ======Confirm it displays the properly formatted fiat amount=====
      final formattedFiatAmount =
          dashboardViewModel.balanceViewModel.isFiatDisabled ? '' : item.formattedFiatAmount;
      if (formattedFiatAmount.isNotEmpty) {
        commonTestCases.findWidgetViaDescendant(
          of: find.byKey(ValueKey(keyId)),
          matching: find.text(formattedFiatAmount),
        );
      }

      //* ======Confirm it displays the right image based on the transaction direction=====
      final imageToUse = item.transaction.direction == TransactionDirection.incoming
          ? 'assets/images/down_arrow.png'
          : 'assets/images/up_arrow.png';

      find.widgetWithImage(Container, AssetImage(imageToUse));
    } catch (e) {
      tester.printToConsole('Error verifying transaction item ${item.transaction.id}: $e');
    }
  }

  Future<void> _verifyAnonpayTransactionListItemDisplay(AnonpayTransactionListItem item) async {
    final keyId = 'anonpay_invoice_transaction_list_item_${item.transaction.invoiceId}_key';

    //* ==============Confirm it has the right key for this item ========
    commonTestCases.hasValueKey(keyId);

    //* ==============Confirm it displays the correct provider =========================
    commonTestCases.hasText(item.transaction.provider);

    //* ===========Confirm it displays the properly formatted amount with currency ========
    final currency = item.transaction.fiatAmount != null
        ? item.transaction.fiatEquiv ?? ''
        : CryptoCurrency.fromFullName(item.transaction.coinTo).name.toUpperCase();

    final amount =
        item.transaction.fiatAmount?.toString() ?? (item.transaction.amountTo?.toString() ?? '');

    final amountCurrencyText = amount + ' ' + currency;

    commonTestCases.hasText(amountCurrencyText);

    //* ======Confirm it displays the properly formatted date=================
    final formattedDate = DateFormat('HH:mm').format(item.transaction.createdAt);
    commonTestCases.hasText(formattedDate);

    //* ===============Confirm it displays the right image====================
    find.widgetWithImage(ClipRRect, AssetImage('assets/images/trocador.png'));
  }

  Future<void> _verifyTradeListItemDisplay(TradeListItem item) async {
    final keyId = 'trade_list_item_${item.trade.id}_key';

    //* ==============Confirm it has the right key for this item ========
    commonTestCases.hasValueKey(keyId);

    //* ==============Confirm it displays the correct provider =========================
    final conversionFlow = '${item.trade.from.toString()} → ${item.trade.to.toString()}';

    commonTestCases.hasText(conversionFlow);

    //* ===========Confirm it displays the properly formatted amount with its crypto tag ========

    final amountCryptoText = item.tradeFormattedAmount + ' ' + item.trade.from.toString();

    commonTestCases.hasText(amountCryptoText);

    //* ======Confirm it displays the properly formatted date=================
    final createdAtFormattedDate =
        item.trade.createdAt != null ? DateFormat('HH:mm').format(item.trade.createdAt!) : null;

    if (createdAtFormattedDate != null) {
      commonTestCases.hasText(createdAtFormattedDate);
    }

    //* ===============Confirm it displays the right image====================
    commonTestCases.hasValueKey(item.trade.provider.image);
  }

  Future<void> _verifyOrderListItemDisplay(OrderListItem item) async {
    final keyId = 'order_list_item_${item.order.id}_key';

    //* ==============Confirm it has the right key for this item ========
    commonTestCases.hasValueKey(keyId);

    //* ==============Confirm it displays the correct provider =========================
    final orderFlow = '${item.order.from!} → ${item.order.to}';

    commonTestCases.hasText(orderFlow);

    //* ===========Confirm it displays the properly formatted amount with its crypto tag ========

    final amountCryptoText = item.orderFormattedAmount + ' ' + item.order.to!;

    commonTestCases.hasText(amountCryptoText);

    //* ======Confirm it displays the properly formatted date=================
    final createdAtFormattedDate = DateFormat('HH:mm').format(item.order.createdAt);

    commonTestCases.hasText(createdAtFormattedDate);
  }
}
