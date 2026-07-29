import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

/// Drives the new UI swap sheet, quote assertions only, it never confirms a trade.
class NewSwapPageRobot extends BaseRobot {
  NewSwapPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(NewSwapPage));
  }

  Future<void> enterDepositAmount(String amount) async {
    await enterTextByKey("swap_page_deposit_amount_field_key", amount);
  }

  /// Waits until a provider quote lands, quotes come from live provider APIs.
  Future<void> confirmQuoteReceived({Duration timeout = const Duration(seconds: 90)}) async {
    final received = await pumpUntil(() => _bestRate() > 0, timeout: timeout);

    expect(received, true, reason: "No provider quote arrived within ${timeout.inSeconds}s");
  }

  double _bestRate() {
    final finder = find.byType(NewSwapPage);

    if (!tester.any(finder)) {
      return 0;
    }

    return tester.widget<NewSwapPage>(finder.first).exchangeViewModel.bestRate;
  }
}
