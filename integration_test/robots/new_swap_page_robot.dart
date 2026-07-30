import "package:cake_wallet/exchange/limits_state.dart";
import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";

/// Drives the new UI swap sheet, only the funds suites go past quote fetching.
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

  /// Enters a deposit amount just above the provider minimum once the limits load.
  Future<void> enterMinimumViableDepositAmount() async {
    final limitsLoaded = await pumpUntil(
      () => _limitsState() is LimitsLoadedSuccessfully,
      timeout: const Duration(seconds: 90),
    );

    expect(limitsLoaded, true, reason: "Provider limits never loaded");

    final min = _limitsMin() ?? 0;

    // 5 percent above the minimum keeps the trade valid when the rate moves slightly,
    // pairs without a minimum fall back to a small fixed amount the team lead can tune.
    final amount = min > 0 ? (min * 1.05).toStringAsFixed(8) : "0.01";
    await enterDepositAmount(amount);
  }

  Future<void> tapSwapButton() async {
    await tapByKey("exchange_page_exchange_button_key");
  }

  /// Waits for the trade to be created, the confirm sheet shows once the provider accepts.
  Future<void> confirmTradeCreated({Duration timeout = const Duration(minutes: 2)}) async {
    await pumpUntilFound(find.byType(SwapConfirmSheet), timeout: timeout);
  }

  /// Waits until the deposit was broadcast, the confirm sheet pops itself after committing.
  Future<void> confirmDepositCommitted({Duration timeout = const Duration(minutes: 3)}) async {
    await pumpUntilGone(find.byType(SwapConfirmSheet), timeout: timeout);
  }

  double? _limitsMin() {
    final finder = find.byType(NewSwapPage);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<NewSwapPage>(finder.first).exchangeViewModel.limits.min;
  }

  LimitsState? _limitsState() {
    final finder = find.byType(NewSwapPage);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<NewSwapPage>(finder.first).exchangeViewModel.limitsState;
  }

  double _bestRate() {
    final finder = find.byType(NewSwapPage);

    if (!tester.any(finder)) {
      return 0;
    }

    return tester.widget<NewSwapPage>(finder.first).exchangeViewModel.bestRate;
  }
}
