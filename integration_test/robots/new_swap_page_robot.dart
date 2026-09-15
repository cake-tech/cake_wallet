import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/exchange/limits_state.dart";
import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_amount_box.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/view_model/send/send_view_model_state.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../core/base_robot.dart";
import "../core/test_config.dart";
import "../core/test_wallets.dart";

class NewSwapPageRobot extends BaseRobot {
  NewSwapPageRobot(super.tester);

  @override
  Future<void> isDisplayed() async {
    await pumpUntilFound(find.byType(NewSwapPage));
  }

  Future<void> enterDepositAmount(String amount) async {
    await enterTextByKey("swap_page_deposit_amount_field_key", amount);
  }

  Future<void> chooseReceiveCurrency(CryptoCurrency currency) async {
    final exchangeViewModel =
        tester.widget<NewSwapPage>(find.byType(NewSwapPage)).exchangeViewModel;

    exchangeViewModel.changeReceiveCurrency(currency: currency);
    await settle();
  }

  Future<void> confirmQuoteReceived({Duration timeout = const Duration(seconds: 90)}) async {
    final received = await pumpUntil(() => _bestRate() > 0, timeout: timeout);

    expect(received, true, reason: "No provider quote arrived within ${timeout.inSeconds}s");
  }

  Future<void> enterMinimumViableDepositAmount() async {
    final limitsLoaded = await pumpUntil(
      () => _limitsState() is LimitsLoadedSuccessfully,
      timeout: const Duration(seconds: 90),
    );

    expect(limitsLoaded, true, reason: "Provider limits never loaded");

    final min = _limitsMin() ?? 0;

    // 5 percent over the minimum, so a small rate move does not invalidate the trade.
    final amount = min > 0 ? (min * 1.05).toStringAsFixed(8) : "0.01";
    await enterDepositAmount(amount);
  }

  Future<String> enterTestReceiveAddress() async {
    final exchangeViewModel =
        tester.widget<NewSwapPage>(find.byType(NewSwapPage)).exchangeViewModel;
    final receiveType = cryptoCurrencyOrTokenToWalletType(exchangeViewModel.receiveCurrency);
    final address = receiveType == null ? "" : TestWallets.receiveAddressFor(receiveType);

    expect(
      address.isNotEmpty,
      true,
      reason: "No test receive address for ${exchangeViewModel.receiveCurrency.title}",
    );

    final receiveCard = find.byWidgetPredicate(
      (widget) => widget is SwapAmountBox && widget.isReceiverCard,
    );

    tester.state<SwapAmountBoxState>(receiveCard).addressController.text = address;
    await settle();

    return address;
  }

  Future<void> confirmSwapButtonEnabled({Duration timeout = TestConfig.walletSyncBudget}) async {
    final button = find.byKey(const ValueKey("exchange_page_exchange_button_key"));

    final enabled = await pumpUntil(
      () => tester.any(button) && !tester.widget<LoadingPrimaryButton>(button).isDisabled,
      timeout: timeout,
    );

    expect(
      enabled,
      true,
      reason: "The swap button stayed disabled with an amount, a quote and a receive address",
    );
  }

  Future<void> tapSwapButton() async {
    await tapByKey("exchange_page_exchange_button_key");
  }

  Future<void> confirmTradeCreated({Duration timeout = const Duration(minutes: 2)}) async {
    await pumpUntilFound(find.byType(SwapConfirmSheet), timeout: timeout);
  }

  void confirmPayoutAddress(String expected) {
    final sheet = tester.widget<SwapConfirmSheet>(find.byType(SwapConfirmSheet));
    final payout = sheet.exchangeTradeViewModel.trade.payoutAddress ?? "";
    final isHex = expected.startsWith("0x");

    expect(
      isHex ? payout.toLowerCase() : payout,
      isHex ? expected.toLowerCase() : expected,
      reason: "The trade pays out somewhere other than the test wallet",
    );
  }

  Future<void> confirmDepositCommitted({Duration timeout = const Duration(minutes: 3)}) async {
    ExecutionState? lastState;

    final committed = await pumpUntil(
      () {
        final sheet = find.byType(SwapConfirmSheet);

        if (!tester.any(sheet)) {
          return true;
        }

        lastState =
            tester.widget<SwapConfirmSheet>(sheet).exchangeTradeViewModel.sendViewModel.state;

        return lastState is TransactionCommitted;
      },
      timeout: timeout,
    );

    expect(
      committed,
      true,
      reason: "The deposit never committed within ${timeout.inMinutes}m, "
          "the sheet reported ${lastState.runtimeType}",
    );

    expect(
      lastState,
      isA<TransactionCommitted>(),
      reason: "The confirm sheet closed before the deposit committed, "
          "it last reported ${lastState.runtimeType}",
    );

    await pumpUntilGone(find.byType(NewSwapPage));
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
