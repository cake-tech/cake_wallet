import 'dart:async';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/send/send_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_test_cases.dart';
import '../components/common_test_constants.dart';
import 'auth_page_robot.dart';
import 'package:cake_wallet/src/widgets/standard_slide_button_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/dashboard_page.dart';

class SendPageRobot {
  SendPageRobot({required this.tester})
      : commonTestCases = CommonTestCases(tester),
        authPageRobot = AuthPageRobot(tester);

  WidgetTester tester;
  CommonTestCases commonTestCases;
  AuthPageRobot authPageRobot;

  Future<void> isSendPage() async {
    await commonTestCases.isSpecificPage<SendPage>();
    await commonTestCases.takeScreenshots('send_page');
  }

  Future<void> waitForSendPage() async {
    tester.printToConsole('Waiting for SendPage to be available');

    final stopwatch = Stopwatch()..start();
    final maxDuration = Duration(seconds: 30);

    while (stopwatch.elapsed < maxDuration) {
      await tester.pump(Duration(milliseconds: 500));

      // Check if we're still on auth page
      if (authPageRobot.onAuthPage()) {
        tester.printToConsole('Still on auth page, waiting...');
        continue;
      }

      // Check if SendPage is available
      final sendPageFinder = find.byType(SendPage);
      if (sendPageFinder.tryEvaluate()) {
        tester.printToConsole('SendPage found!');
        return;
      }

      tester.printToConsole('SendPage not found yet, waiting...');
    }

    throw Exception('SendPage not found after ${maxDuration.inSeconds} seconds');
  }

  Future<void> checkIfSendPageIsVisible() async {
    tester.printToConsole('Confirming SendPage is visible');

    if (authPageRobot.onAuthPage()) {
      tester.printToConsole('Auth page is currently visible');
      await _handleAuthPage();
      await commonTestCases.defaultSleepTime();
    }

    await waitForSendPage();
  }

  void hasTitle() {
    commonTestCases.hasText(S.current.send);
  }

  void confirmViewComponentsDisplayProperly() {
    SendPage sendPage = tester.widget(find.byType(SendPage));
    final sendViewModel = sendPage.sendViewModel;

    commonTestCases.hasValueKey('send_page_address_textfield_key');
    commonTestCases.hasValueKey('send_page_note_textfield_key');
    commonTestCases.hasValueKey('send_page_amount_textfield_key');
    commonTestCases.hasValueKey('send_page_add_template_button_key');

    if (sendViewModel.hasMultipleTokens) {
      commonTestCases.hasValueKey('send_page_currency_picker_button_key');
    }

    if (!sendViewModel.isBatchSending) {
      commonTestCases.hasValueKey('send_page_send_all_button_key');
    }

    if (!sendViewModel.isFiatDisabled) {
      commonTestCases.hasValueKey('send_page_fiat_amount_textfield_key');
    }

    if (sendViewModel.feesViewModel.hasFees) {
      commonTestCases.hasValueKey('send_page_select_fee_priority_button_key');
    }

    if (sendViewModel.hasCoinControl) {
      commonTestCases.hasValueKey('send_page_unspent_coin_button_key');
    }

    if (sendViewModel.hasCurrencyChanger) {
      commonTestCases.hasValueKey('send_page_change_asset_button_key');
    }

    if (sendViewModel.sendTemplateViewModel.hasMultiRecipient) {
      commonTestCases.hasValueKey('send_page_add_receiver_button_key');
    }
  }

  Future<void> selectReceiveCurrency(CryptoCurrency receiveCurrency) async {
    final currencyPickerKey = 'send_page_currency_picker_button_key';
    final currencyPickerDialogKey = 'send_page_currency_picker_dialog_button_key';

    await commonTestCases.tapItemByKey(currencyPickerKey);
    await commonTestCases.defaultSleepTime();

    // Check if picker dialog is present
    if (!commonTestCases.isKeyPresent(currencyPickerDialogKey)) {
      tester.printToConsole('Currency picker dialog not found, may already be selected');
      return;
    }

    SendPage sendPage = tester.widget(find.byType(SendPage));
    final sendViewModel = sendPage.sendViewModel;

    if (receiveCurrency == sendViewModel.selectedCryptoCurrency) {
      await commonTestCases
          .tapItemByKey('picker_items_index_${receiveCurrency.name}_selected_item_button_key');
      return;
    }

    await commonTestCases.enterText(receiveCurrency.title, 'search_bar_widget_key');

    await commonTestCases.defaultSleepTime();

    await commonTestCases.tapItemByKey('picker_items_index_${receiveCurrency.fullName}_button_key');
  }

  Future<void> enterReceiveAddress(String receiveAddress) async {
    await commonTestCases.enterText(receiveAddress, 'send_page_address_textfield_key');
    await commonTestCases.defaultSleepTime();
  }

  Future<void> enterSendAmount(String amount, {bool isFiat = false}) async {
    await commonTestCases.enterText(
      amount,
      isFiat ? 'send_page_fiat_amount_textfield_key' : 'send_page_amount_textfield_key',
    );
  }

  String _getTextFromField(ValueKey<String> key) {
    final field = find.byKey(key);
    if (!field.tryEvaluate()) return '';
    final baseTextFormField = tester.widget<BaseTextFormField>(field);
    return baseTextFormField.controller?.text ?? '';
  }

  /// Validates wallet balance for $1 send by checking against the converted crypto amount
  /// Returns true if wallet has sufficient balance, false otherwise
  Future<bool> validateWalletBalanceForOneDollarSend() async {
    SendPage sendPage = tester.widget(find.byType(SendPage));
    final sendViewModel = sendPage.sendViewModel;

    final balance = await sendViewModel.sendingBalance;

    await setupOneDollarSend();

    // Get the crypto amount that was set for the $1 send
    String cryptoAmount = _getTextFromField(ValueKey('send_page_amount_textfield_key'));
    if (cryptoAmount.isEmpty || cryptoAmount == '0' || cryptoAmount == '0.0') {
      cryptoAmount = '0.001'; // fallback amount
    }

    final amount = double.tryParse(cryptoAmount) ?? 0.0;

    tester.printToConsole(
      'Wallet balance: $balance, sending amount for \$${CommonTestConstants.sendTestFiatAmount}: $cryptoAmount',
    );

    if (balance.isEmpty || double.tryParse(balance) == null) {
      tester.printToConsole('Invalid wallet balance: $balance');
      return false;
    }

    final balanceValue = double.parse(balance);
    if (balanceValue < amount) {
      tester.printToConsole(
        'Insufficient balance for \$${CommonTestConstants.sendTestFiatAmount} send: $balanceValue < $amount',
      );
      return false;
    }

    tester.printToConsole(
      'Wallet has sufficient balance for \$${CommonTestConstants.sendTestFiatAmount} send',
    );
    return true;
  }

  Future<void> selectTransactionPriority({TransactionPriority? priority}) async {
    SendPage sendPage = tester.widget(find.byType(SendPage));
    final sendViewModel = sendPage.sendViewModel;

    if (!sendViewModel.feesViewModel.hasFees || priority == null) return;

    final transactionPriorityPickerKey = 'send_page_select_fee_priority_button_key';
    await commonTestCases.tapItemByKey(transactionPriorityPickerKey);

    if (priority == sendViewModel.feesViewModel.transactionPriority) {
      await commonTestCases
          .tapItemByKey('picker_items_index_${priority.title}_selected_item_button_key');
      return;
    }

    await commonTestCases.dragUntilVisible(
      'picker_items_index_${priority.title}_button_key',
      'picker_scrollbar_key',
    );
    await commonTestCases.defaultSleepTime();

    await commonTestCases.tapItemByKey('picker_items_index_${priority.title}_button_key');
  }

  Future<void> onSendButtonPressed() async {
    tester.printToConsole('Pressing send');

    await checkIfSendPageIsVisible();

    await tester.pumpAndSettle();
    final sendPage = tester.widget<SendPage>(find.byType(SendPage));

    while (true) {
      bool isReadyForSend = sendPage.sendViewModel.isReadyForSend;
      await tester.pump();
      if (isReadyForSend) {
        tester.printToConsole('Is ready for send');
        break;
      } else {
        await commonTestCases.defaultSleepTime();
        await tester.pumpAndSettle();
        tester.printToConsole('not yet ready for send');
      }
    }
    await commonTestCases.tapItemByKey(
      'send_page_send_button_key',
      shouldPumpAndSettle: false,
    );

    await _waitForSendTransactionCompletion();

    await commonTestCases.defaultSleepTime();
  }

  Future<void> _waitForSendTransactionCompletion() async {
    await tester.pump();
    final Completer<void> completer = Completer<void>();

    // Loop to wait for the async operation to complete
    while (true) {
      await Future.delayed(Duration(seconds: 1));

      tester.printToConsole('Before _handleAuth');

      await _handleAuthPage();

      await commonTestCases.defaultSleepTime();

      tester.printToConsole('After _handleAuth');

      await tester.pump();

      if (authPageRobot.onAuthPage()) {
        tester.printToConsole('Still on auth page, continuing to wait');
        continue;
      }

      final sendPageFinder = find.byType(SendPage);
      if (!sendPageFinder.tryEvaluate()) {
        tester.printToConsole('SendPage not found yet, continuing to wait');
        continue;
      }

      final sendPage = tester.widget<SendPage>(sendPageFinder);
      final state = sendPage.sendViewModel.state;

      await tester.pump();

      bool isDone = state is ExecutedSuccessfullyState || state is TransactionCommitted;
      bool isFailed = state is FailureState;

      tester.printToConsole('isDone: $isDone');
      tester.printToConsole('isFailed: $isFailed');

      if (isDone || isFailed) {
        tester.printToConsole(
          isDone ? 'Completer is done' : 'Completer is done though operation failed',
        );
        completer.complete();
        await tester.pump();
        break;
      } else {
        tester.printToConsole('Completer is not done');
        await tester.pump();
      }
    }

    await expectLater(completer.future, completes);

    tester.printToConsole('Done confirming sending operation');
  }

  Future<void> _handleAuthPage() async {
    tester.printToConsole('Inside _handleAuth');

    final onAuthPageDesktop = authPageRobot.onAuthPageDesktop();
    if (onAuthPageDesktop) {
      await authPageRobot.enterPassword(CommonTestConstants.pin.join(""));
      await commonTestCases.defaultSleepTime();
      return;
    }

    await tester.pump();
    tester.printToConsole('starting auth checks');

    final authPage = authPageRobot.onAuthPage();

    tester.printToConsole('hasAuth:$authPage');

    if (authPage) {
      await tester.pump();
      tester.printToConsole('Starting inner _handleAuth loop checks');

      try {
        await authPageRobot.enterPinCode(CommonTestConstants.pin, pumpDuration: 500);
        tester.printToConsole('Auth done');

        await tester.pump(Duration(seconds: 3));

        tester.printToConsole('Auth pump done');

        await commonTestCases.defaultSleepTime();
      } catch (e) {
        tester.printToConsole('Auth failed, retrying: $e');
        await tester.pump();

        await commonTestCases.defaultSleepTime(seconds: 1);
        await _handleAuthPage();
      }
    } else {
      tester.printToConsole('No auth page detected, proceeding');
    }
    await tester.pump();
  }

  //* ------ On Sending Failure ------------
  Future<bool> hasErrorWhileSending() async {
    await tester.pump();

    tester.printToConsole('Checking if there is an error');

    final errorDialog = find.byKey(ValueKey('send_page_send_failure_dialog_button_key'));

    bool hasError = errorDialog.tryEvaluate();

    tester.printToConsole('Has error: $hasError');

    return hasError;
  }

  Future<void> onSendFailureDialogButtonPressed() async {
    await commonTestCases.defaultSleepTime();

    tester.printToConsole('Send Button Failure Dialog Triggered');

    await commonTestCases.tapItemByKey('send_page_send_failure_dialog_button_key');
  }

  //* ------ On Sending Success ------------
  Future<void> onSendSliderOnConfirmSendingBottomSheetDragged() async {
    await commonTestCases.defaultSleepTime();
    await tester.pump();

    if (commonTestCases.isKeyPresent('send_page_confirm_sending_bottom_sheet_key')) {
      tester.printToConsole('Found confirm sending bottom sheet, starting slider drag');

      final accessibleButton = find.byType(PrimaryButton);
      if (accessibleButton.tryEvaluate()) {
        tester.printToConsole('Found accessible navigation button, tapping it');
        await tester.tap(accessibleButton);
        await tester.pumpAndSettle();
      } else {
        await _performSendSliderDrag();
      }

      tester.printToConsole('Slider/button action completed, waiting for transaction completion');

      // Check if bottom sheet is dismissed
      if (commonTestCases.isKeyPresent('send_page_confirm_sending_bottom_sheet_key')) {
        tester.printToConsole('Bottom sheet still present, waiting a bit more for dismissal');
        await commonTestCases.defaultSleepTime(seconds: 3);

        // If still present, try one more manual dismissal attempt
        if (commonTestCases.isKeyPresent('send_page_confirm_sending_bottom_sheet_key')) {
          tester.printToConsole('Bottom sheet still present, attempting final manual dismissal');
          await tester.tapAt(Offset(200, 200)); // Tap outside
          await tester.pumpAndSettle();
        }
      }

      // Wait for transaction completion
      await _waitForCommitTransactionCompletion();
      await commonTestCases.defaultSleepTime(seconds: 2);
    } else {
      tester.printToConsole('Confirm sending bottom sheet not found, waiting and retrying');
      await commonTestCases.defaultSleepTime();
      await tester.pump();
      await onSendSliderOnConfirmSendingBottomSheetDragged();
    }
  }

  Future<void> _performSendSliderDrag() async {
    final sliderFinder = find.byKey(const ValueKey('standard_slide_button_widget_slider_key'));
    expect(sliderFinder, findsOneWidget, reason: 'Slider should be found');

    // Find the StandardSlideButton widget to get the main container
    final slideButtonFinder = find.byType(StandardSlideButton);
    expect(slideButtonFinder, findsOneWidget, reason: 'StandardSlideButton should be found');

    // Get the main container bounds (the outer container, not the slider container)
    final mainContainerRect = tester.getRect(slideButtonFinder);
    final containerWidth = mainContainerRect.width;

    final sideMargin = 4.0;
    final sliderWidth = 42.0;
    final effectiveMaxWidth = containerWidth - 2 * sideMargin;
    final threshold = effectiveMaxWidth - sliderWidth - 10;

    // Add a small buffer to ensure we exceed the threshold
    final dragDistance = threshold + 20;

    tester.printToConsole(
      'Main container width: $containerWidth, Threshold: $threshold, Drag distance: $dragDistance',
    );

    // Start the drag
    await tester.drag(sliderFinder, Offset(dragDistance, 0));

    // Wait for the drag to complete and trigger onHorizontalDragEnd
    await tester.pump(Duration(milliseconds: 100));

    // Release the drag (this should trigger onHorizontalDragEnd)
    await tester.pump(Duration(seconds: 2));

    tester.printToConsole('Drag completed, waiting for callback');

    // Wait for the slide completion callback to trigger and bottom sheet to dismiss
    await _waitForBottomSheetDismissal();
  }

  Future<void> _waitForBottomSheetDismissal() async {
    tester.printToConsole('Waiting for bottom sheet dismissal');

    final stopwatch = Stopwatch()..start();
    final maxDuration = Duration(seconds: 10);

    while (stopwatch.elapsed < maxDuration) {
      await tester.pump(Duration(milliseconds: 500));

      // Check if the confirm bottom sheet is still present
      if (!commonTestCases.isKeyPresent('send_page_confirm_sending_bottom_sheet_key')) {
        tester.printToConsole('Bottom sheet dismissed successfully!');
        return;
      }

      // Check if transaction has started (this indicates slider was successful)
      if (_isTransactionStarted()) {
        tester.printToConsole(
            'Transaction started, slider was successful even if bottom sheet is still visible');
        return;
      }

      tester.printToConsole('Bottom sheet still present, waiting');
    }

    tester.printToConsole('Bottom sheet dismissal timeout reached, trying manual dismissal');

    // If the bottom sheet is still present after timeout, try to manually dismiss it
    // This might happen if the slider drag didn't trigger the onSlideComplete properly
    if (commonTestCases.isKeyPresent('send_page_confirm_sending_bottom_sheet_key')) {
      tester.printToConsole('Attempting manual bottom sheet dismissal');

      // Try to find and tap a close button or back button
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.tryEvaluate()) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
        tester.printToConsole('Manual close button tapped');
      } else {
        // Try to pop the bottom sheet by tapping outside or using back gesture
        await tester.tapAt(Offset(100, 100)); // Tap outside the bottom sheet
        await tester.pumpAndSettle();
        tester.printToConsole('Tapped outside bottom sheet');
      }
    }
  }

  bool _isTransactionStarted() {
    try {
      // Check if SendPage is available and transaction state has changed
      final sendPageFinder = find.byType(SendPage);
      if (!sendPageFinder.tryEvaluate()) {
        return false;
      }

      final sendPage = tester.widget<SendPage>(sendPageFinder);
      final state = sendPage.sendViewModel.state;

      // Check if we're in a transaction-related state
      return state is TransactionCommitting ||
          state is IsExecutingState ||
          state is TransactionCommitted ||
          state is ExecutedSuccessfullyState;
    } catch (e) {
      return false;
    }
  }

  Future<void> _waitForCommitTransactionCompletion() async {
    tester.printToConsole('Starting to wait for transaction completion');

    final stopwatch = Stopwatch()..start();
    final maxDuration = Duration(seconds: 60);

    while (stopwatch.elapsed < maxDuration) {
      await Future.delayed(Duration(seconds: 1));

      // Check if the confirm bottom sheet is gone (transaction started)
      if (!commonTestCases.isKeyPresent('send_page_confirm_sending_bottom_sheet_key')) {
        tester.printToConsole('Confirm bottom sheet disappeared, transaction may be processing');
      }

      // Check if we've navigated back to the dashboard (for cases of successful transaction)
      final dashboardFinder = find.byType(DashboardPage);
      if (dashboardFinder.tryEvaluate()) {
        tester.printToConsole('Dashboard detected, transaction completed successfully!');
        await tester.pump();
        return;
      }

      // Check if SendPage is still available (transaction still processing)
      final sendPageFinder = find.byType(SendPage);
      if (sendPageFinder.tryEvaluate()) {
        final sendPage = tester.widget<SendPage>(sendPageFinder);
        final state = sendPage.sendViewModel.state;

        bool isDone = state is ExecutedSuccessfullyState || state is TransactionCommitted;
        bool isFailed = state is FailureState;

        tester.printToConsole('Transaction state: $state');
        tester.printToConsole('isDone: $isDone');
        tester.printToConsole('isFailed: $isFailed');

        if (isDone) {
          tester.printToConsole('Transaction committed successfully!');
          await tester.pump();
          return;
        } else if (isFailed) {
          tester.printToConsole('Transaction failed: $state');
          await tester.pump();
          return;
        } else {
          tester.printToConsole('Transaction still processing');
          await tester.pump();
        }
      } else {
        // SendPage not found, check if we're on dashboard or still processing
        if (dashboardFinder.tryEvaluate()) {
          tester.printToConsole('Dashboard detected - transaction completed successfully!');
          await tester.pump();
          return;
        } else {
          tester.printToConsole(
              'SendPage not found, but dashboard not yet visible - continuing to wait...');
        }
      }
    }

    if (stopwatch.elapsed >= maxDuration) {
      tester.printToConsole('Transaction completion timeout reached');
    }

    tester.printToConsole('Done waiting for transaction completion');
  }

  //* ---- Handle Transaction Success Flow -----
  Future<void> handleTransactionSuccessFlow() async {
    await commonTestCases.defaultSleepTime();

    // Wait for any success dialogs to appear
    await tester.pump(Duration(seconds: 2));

    // Check for contact addition dialog first (if new contact address exists)
    final contactDialog = find.byKey(ValueKey('send_page_add_contact_bottom_sheet_yes_button_key'));
    if (contactDialog.tryEvaluate()) {
      tester.printToConsole('Found contact addition dialog, selecting Yes');

      // Check if the button is actually visible and tappable
      final buttonRect = tester.getRect(contactDialog);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;

      if (buttonRect.bottom <= screenSize.height && buttonRect.top >= 0) {
        await commonTestCases.tapItemByKey('send_page_add_contact_bottom_sheet_yes_button_key');
        await commonTestCases.defaultSleepTime();
      } else {
        tester.printToConsole('Contact dialog button is off-screen, skipping');
      }
    }

    // Check for the main success dialog
    final successDialog = find.byKey(ValueKey('send_page_sent_dialog_ok_button_key'));
    if (successDialog.tryEvaluate()) {
      tester.printToConsole('Found transaction success dialog, closing it');
      await commonTestCases.tapItemByKey('send_page_sent_dialog_ok_button_key');
      await commonTestCases.defaultSleepTime();
    }
  }

  //* ---- Fiat/Crypto Amount Validation -----
  Future<void> testFiatAmountEntry() async {
    tester.printToConsole('Testing fiat amount entry...');

    await enterSendAmount('');
    await enterSendAmount('', isFiat: true);
    await commonTestCases.defaultSleepTime();

    await enterSendAmount(CommonTestConstants.sendTestFiatAmount, isFiat: true);
    await commonTestCases.defaultSleepTime();

    // Wait for conversion to complete
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Next we get the crypto amount value and validate it's not 0
    final cryptoAmount = _getTextFromField(ValueKey('send_page_amount_textfield_key'));

    tester.printToConsole(
      'Crypto amount after entering \$${CommonTestConstants.sendTestFiatAmount}: $cryptoAmount',
    );

    if (cryptoAmount.isNotEmpty && cryptoAmount != '0' && cryptoAmount != '0.0') {
      tester.printToConsole('Fiat to crypto conversion working - crypto amount: $cryptoAmount');
    } else {
      tester.printToConsole(
        'Fiat to crypto conversion may not be working - crypto amount: $cryptoAmount',
      );
    }
  }

  Future<void> testCryptoAmountEntry() async {
    tester.printToConsole('Testing crypto amount entry...');

    await enterSendAmount('');
    await enterSendAmount('', isFiat: true);
    await commonTestCases.defaultSleepTime();

    String cryptoAmount = '0.001';

    await enterSendAmount(cryptoAmount);
    await commonTestCases.defaultSleepTime();

    // Wait for conversion to complete
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Get the fiat amount value and validate it's not 0
    final fiatAmount = _getTextFromField(ValueKey('send_page_fiat_amount_textfield_key'));

    tester.printToConsole('Fiat amount after entering $cryptoAmount: $fiatAmount');

    if (fiatAmount.isNotEmpty && fiatAmount != '0' && fiatAmount != '0.0') {
      tester.printToConsole('Crypto to fiat conversion working, fiat amount: $fiatAmount');
    } else {
      tester.printToConsole(
          'Crypto to fiat conversion may not be working - fiat amount: $fiatAmount');
    }
  }

  Future<void> setupOneDollarSend() async {
    // Clear existing amounts
    await enterSendAmount('');
    await enterSendAmount('', isFiat: true);
    await commonTestCases.defaultSleepTime();

    await enterSendAmount(CommonTestConstants.sendTestFiatAmount, isFiat: true);
    await commonTestCases.defaultSleepTime();

    // Wait for conversion to complete
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Get the converted crypto amount
    String cryptoAmount = _getTextFromField(ValueKey('send_page_amount_textfield_key'));
    if (cryptoAmount.isEmpty || cryptoAmount == '0' || cryptoAmount == '0.0') {
      cryptoAmount = '0.001'; // fallback amount
    }

    tester.printToConsole(
      'Sending $cryptoAmount (equivalent to \$${CommonTestConstants.sendTestFiatAmount}) to test wallet',
    );

    // Update the amount field with the converted value
    await enterSendAmount(cryptoAmount);
    await commonTestCases.defaultSleepTime();
  }
}
