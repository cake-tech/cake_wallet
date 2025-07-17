import 'package:flutter_test/flutter_test.dart';

import 'package:cake_wallet/src/screens/exchange_trade/exchange_trade_external_send_page.dart';

import '../components/common_test_cases.dart';

class ExchangeTradeExternalSendPageRobot {
  ExchangeTradeExternalSendPageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isExchangeTradeExternalSendPage() async {
    await commonTestCases.isSpecificPage<ExchangeTradeExternalSendPage>();
    await commonTestCases.takeScreenshots('exchange_trade_external_send_page');
  }

  Future<void> verifySendDetailsItemsDisplayProperly() async {
    final widget =
        tester.widget<ExchangeTradeExternalSendPage>(find.byType(ExchangeTradeExternalSendPage));
    final exchangeTradeViewModel = widget.exchangeTradeViewModel;
    final items = exchangeTradeViewModel.items.where((item) => item.isExternalSendDetail).toList();

    for (var item in items) {
      commonTestCases.hasValueKey('exchange_trade_external_send_page_send_item_${item.title}_key');
      tester.printToConsole('${item.title} present on screen');
    }

    commonTestCases.defaultSleepTime();
  }

  Future<void> onContinueButtonPressed() async {
    await commonTestCases.tapItemByKey('exchange_trade_external_send_page_continue_button_key');
  }
}
