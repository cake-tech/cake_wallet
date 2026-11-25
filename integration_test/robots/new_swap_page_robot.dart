import "package:cake_wallet/di.dart";
import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_amount_box.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_confirm_sheet.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
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
    await tapByKey("swap_amount_box_receive_currency_button_key");

    final search = find.descendant(
      of: find.byType(CurrencyPickerSearchField),
      matching: find.byType(EditableText),
    );

    await pumpUntilFound(search);

    await tester.enterText(search.first, currency.title);
    await settle(max: const Duration(seconds: 2));

    await tapWhenVisible(
      find.byWidgetPredicate(
        (widget) => widget is CurrencyPickerRow && _isSameCurrency(widget.currency, currency),
      ),
    );

    final chosen = await pumpUntil(() {
      final payoutCurrency = _inputs?.payoutAmount.currency;

      return payoutCurrency != null && _isSameCurrency(payoutCurrency, currency);
    });

    expect(
      chosen,
      true,
      reason: "The picker did not switch the receive currency to ${currency.title}",
    );
  }

  static bool _isSameCurrency(CryptoCurrency one, CryptoCurrency other) =>
      one.title.toLowerCase() == other.title.toLowerCase() &&
      (one.tag ?? "").toLowerCase() == (other.tag ?? "").toLowerCase();

  Future<void> confirmQuoteReceived({Duration timeout = const Duration(seconds: 90)}) async {
    final received = await pumpUntil(() => _currentRates != null, timeout: timeout);

    expect(
      received,
      true,
      reason: "No provider quote arrived within ${timeout.inSeconds}s, "
          "the rates were ${_bloc?.rateCubit.state.runtimeType}",
    );
  }

  Future<void> enterMinimumViableDepositAmount() async {
    final inputs = _inputs;

    expect(inputs, isNotNull, reason: "The swap page never showed its amounts");

    final limits = await _providerLimits(inputs!);

    expect(limits, isNotEmpty, reason: "Provider limits never loaded");

    final min = limits.any((limits) => limits.min == null)
        ? null
        : limits.map((limits) => limits.min!).reduce((a, b) => a < b ? a : b);

    // 5 percent over the minimum, so a small rate move does not invalidate the trade.
    final amount = min == null || min.isZero
        ? "0.01"
        : (min * BigInt.from(105) / BigInt.from(100)).toString();
    await enterDepositAmount(amount);
  }

  Future<String> enterTestReceiveAddress() async {
    final payoutCurrency = _inputs?.payoutAmount.currency;
    final receiveType =
        payoutCurrency == null ? null : cryptoCurrencyOrTokenToWalletType(payoutCurrency);
    final address = receiveType == null ? "" : TestWallets.receiveAddressFor(receiveType);

    expect(
      address.isNotEmpty,
      true,
      reason: "No test receive address for ${payoutCurrency?.title}",
    );

    await Clipboard.setData(ClipboardData(text: address));
    await tapWhenVisible(_receivePasteButton);

    final entered = await pumpUntil(() => _inputs?.payoutAddress?.address == address);

    expect(entered, true, reason: "The swap page did not take $address as the receive address");

    return address;
  }

  Future<void> confirmSwapButtonEnabled({Duration timeout = TestConfig.walletSyncBudget}) async {
    final enabled = await pumpUntil(
      () =>
          tester.any(_swapButton) && !tester.widget<NewPrimaryButton>(_swapButton.first).disabled,
      timeout: timeout,
    );

    expect(
      enabled,
      true,
      reason: "The swap button stayed disabled with an amount, a quote and a receive address",
    );
  }

  Future<void> tapSwapButton() async {
    await tapWhenVisible(_swapButton);
  }

  Future<void> confirmTradeCreated({Duration timeout = const Duration(minutes: 2)}) async {
    await pumpUntilFound(find.byType(SwapConfirmSheet), timeout: timeout);

    SwapState? lastState;

    await pumpUntil(
      () {
        lastState = _sheetState;

        return lastState is SwapStateWithTrade || lastState is SwapFailureState;
      },
      timeout: timeout,
    );

    expect(
      lastState,
      isA<SwapStateWithTrade>(),
      reason: "No trade was created within ${timeout.inMinutes}m, "
          "the sheet reported ${_describe(lastState)}",
    );
  }

  void confirmPayoutAddress(String expected) {
    final state = _sheetState;
    final payout = state is SwapStateWithTrade ? state.trade.payoutAddress : "";
    final isHex = expected.startsWith("0x");

    expect(
      isHex ? payout.toLowerCase() : payout,
      isHex ? expected.toLowerCase() : expected,
      reason: "The trade pays out somewhere other than the test wallet",
    );
  }

  Future<void> confirmDepositCommitted({Duration timeout = const Duration(minutes: 3)}) async {
    SwapState? lastState;

    final settled = await pumpUntil(
      () {
        if (!tester.any(find.byType(SwapConfirmSheet))) {
          return true;
        }

        lastState = _sheetState;

        return lastState is SwapTransactionCommitted || lastState is SwapFailureState;
      },
      timeout: timeout,
    );

    expect(
      settled,
      true,
      reason: "The deposit never committed within ${timeout.inMinutes}m, "
          "the sheet reported ${_describe(lastState)}",
    );

    expect(
      lastState,
      isA<SwapTransactionCommitted>(),
      reason: "The deposit did not commit, the sheet last reported ${_describe(lastState)}",
    );

    await tapWhenVisible(
      find.descendant(
        of: find.byType(TransactionCommitedScreen),
        matching: find.byType(NewPrimaryButton),
      ),
    );

    await pumpUntilGone(find.byType(NewSwapPage));
  }

  Future<List<ExchangeLimits>> _providerLimits(SwapStateWithInputs inputs) async {
    final registry = getIt.get<ExchangeProviderRegistry>();

    final limits = await Future.wait(
      inputs.usableProviders.map(
        (provider) => registry
            .getProvider(provider)
            .fetchLimits(
              from: inputs.depositAmount.currency,
              to: inputs.payoutAmount.currency,
              isFixedRateMode: false,
            )
            .timeout(const Duration(seconds: 7))
            .then<ExchangeLimits?>((limits) => limits, onError: (_) => null),
      ),
    );

    return limits.whereType<ExchangeLimits>().toList();
  }

  static String _describe(SwapState? state) => switch (state) {
        final SwapFailureState failure => "${failure.runtimeType}: ${failure.error}",
        _ => "${state.runtimeType}",
      };

  Finder get _swapButton => find.descendant(
        of: find.byType(NewSwapPage),
        matching: find.byType(NewPrimaryButton),
      );

  Finder get _receivePasteButton => find.descendant(
        of: find.byWidgetPredicate((widget) => widget is SwapAmountBox && widget.isReceiverCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is ModernButton && widget.svgPath == "assets/new-ui/paste.svg",
        ),
      );

  SwapBloc? get _bloc {
    final finder = find.byType(NewSwapPage);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<NewSwapPage>(finder.first).bloc;
  }

  SwapStateWithInputs? get _inputs {
    final state = _bloc?.state;

    return state is SwapStateWithInputs ? state : null;
  }

  RatesLoaded? get _currentRates {
    final rates = _bloc?.rateCubit.state;

    return rates is RatesLoaded && rates.request == _inputs?.rateRequest ? rates : null;
  }

  SwapState? get _sheetState {
    final finder = find.byType(SwapConfirmSheet);

    if (!tester.any(finder)) {
      return null;
    }

    return tester.widget<SwapConfirmSheet>(finder.first).bloc.state;
  }
}
