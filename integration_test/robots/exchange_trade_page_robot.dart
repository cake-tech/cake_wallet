import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_checks.dart';

class ExchangeTradePageRobot {
  ExchangeTradePageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isExchangeTradePage() async {
    await commonTestCases.isSpecificPage<ExchangeTradePage>();
  }

  void hasInformationDialog() {
    commonTestCases.hasValueKey('information_page_dialog_key');
  }

  Future<void> onGotItButtonPressed() async {
    await commonTestCases.tapItemByKey('information_page_got_it_button_key');
    await commonTestCases.defaultSleepTime();
  }

  Future<void> onConfirmSendingButtonPressed() async {
    await commonTestCases.tapItemByKey('exchange_trade_page_confirm_sending_button_key');
  }

  Future<void> onSendButtonOnConfirmSendingDialogPressed() async {
    await commonTestCases
        .tapItemByKey('exchange_trade_page_confirm_sending_dialog_send_button_key');
    await commonTestCases.defaultSleepTime();
  }

  Future<void> onCancelButtonOnConfirmSendingDialogPressed() async {
    await commonTestCases
        .tapItemByKey('exchange_trade_page_confirm_sending_dialog_cancel_button_key');
    await commonTestCases.defaultSleepTime();
  }

  bool hasErrorWhileSending() {
    final errorDialog = find.byKey(ValueKey('exchange_trade_page_send_failure_dialog_button_key'));
    bool hasError = errorDialog.tryEvaluate();
    return hasError;
  }

  Future<void> onSendFailureDialogButtonPressed() async {
    await commonTestCases.tapItemByKey('exchange_trade_page_send_failure_dialog_button_key');
    await commonTestCases.defaultSleepTime();
  }

  // Future<void> handleSendSuccessOrFailure() async {
  //   bool hasError = false;

  //   hasError = hasErrorWhileSending();

  //   if (hasError) {
  //     tester.printToConsole('hasError: $hasError');
  //     await onSendFailureDialogButtonPressed();
  //     tester.printToConsole('Failure button tapped');
  //     await onConfirmSendingButtonPressed();
  //     tester.printToConsole('Confirm sending tapped');
  //     await handleSendSuccessOrFailure();
  //     tester.printToConsole('Let\'s go');
  //   } else {
  //     await onSendButtonOnConfirmSendingDialogPressed();
  //     return;
  //   }
  // }
}
