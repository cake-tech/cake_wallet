import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_amount_box.dart";
import "package:cake_wallet/view_model/exchange/exchange_view_model.dart";
import "package:cake_wallet/view_model/wallet_switcher_view_model.dart";
import "package:cw_core/balance.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart" show Observable, runInAction;
import "package:mocktail/mocktail.dart";

class _MockExchange extends Mock implements ExchangeViewModel {}

class _MockSwitcher extends Mock implements WalletSwitcherViewModel {}

class _MockWallet extends Mock
    implements WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> {}

void main() {
  setUpAll(() async {
    await S.delegate.load(const Locale("en", ""));
  });
  late Observable<FiatCurrency> fiat;
  late Observable<String> conversion;
  late _MockExchange model;

  setUp(() {
    fiat = Observable(FiatCurrency.usd);
    conversion = Observable("300.00");
    model = _MockExchange();
    final wallet = _MockWallet();
    when(() => wallet.type).thenReturn(WalletType.monero);
    when(() => wallet.name).thenReturn("Test wallet");
    when(() => model.wallet).thenReturn(wallet);
    when(() => model.amountParsingProxy)
        .thenReturn(const AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin));
    when(() => model.fiat).thenAnswer((_) => fiat.value);
    when(() => model.isFixedRateMode).thenReturn(false);
    when(() => model.isSendFromExternal).thenReturn(false);
    when(() => model.hasAllAmount).thenReturn(false);
    when(() => model.receiveAddressExtraId).thenReturn("");
    when(() => model.receiveAddress).thenReturn("");
    when(() => model.depositAddress).thenReturn("");
    when(() => model.receiveAmount).thenReturn("1");
    when(() => model.depositAmount).thenReturn("1");
    when(() => model.receiveCurrency).thenReturn(CryptoCurrency.xmr);
    when(() => model.depositCurrency).thenReturn(CryptoCurrency.xmr);
    when(() => model.receiveAmountFiat).thenAnswer((_) => conversion.value);
    when(() => model.depositAmountFiat).thenAnswer((_) => conversion.value);
    when(() => model.roundedReceiveAmount(any())).thenReturn("1");
    when(() => model.roundedDepositAmount(any())).thenReturn("1");
    when(() => model.roundedReceiveAmountFiat(any())).thenAnswer((_) => conversion.value);
    when(() => model.roundedDepositAmountFiat(any())).thenAnswer((_) => conversion.value);
  });

  Future<SwapAmountBoxState> showBox(WidgetTester tester, {required bool receiver}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale("en", "")],
        home: Scaffold(
          body: SingleChildScrollView(
            child: SwapAmountBox(
              exchangeViewModel: model,
              isReceiverCard: receiver,
              walletSwitcherViewModel: _MockSwitcher(),
              currency: CryptoCurrency.xmr,
              currencies: const [CryptoCurrency.xmr],
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<SwapAmountBoxState>(find.byType(SwapAmountBox));
  }

  for (final receiver in [false, true]) {
    testWidgets("${receiver ? 'receive' : 'deposit'} clears old fiat input and refreshes new fiat",
        (tester) async {
      final state = await showBox(tester, receiver: receiver);
      state.updateFiatAmount();
      expect(state.fiatAmountController.text, "300");
      state.amountFocusNode.requestFocus();
      await tester.pump();
      runInAction(() {
        fiat.value = FiatCurrency.uah;
        conversion.value = "";
      });
      await tester.pump();
      expect(state.fiatAmountController.text, isEmpty);
      runInAction(() => conversion.value = "12000.00");
      await tester.pump();
      expect(state.fiatAmountController.text, "12000");
    });
  }

  testWidgets("the fiat switch selects the fiat controller without changing crypto text",
      (tester) async {
    final state = await showBox(tester, receiver: false);
    state.amountController.text = "1";
    final bar = find.byType(FiatAmountBar);
    await tester.tap(find.descendant(of: bar, matching: find.byType(IconButton)).first);
    await tester.pump();
    expect(state.fiatInputMode, true);
    expect(tester.widget<FiatAmountBar>(bar).fiatInputMode, true);
    final field = find.byKey(const ValueKey("swap_page_deposit_amount_field_key"));
    expect(tester.widget<TextField>(field).controller, same(state.fiatAmountController));
    expect(state.fiatAmountController.text, "300");
    expect(state.amountController.text, "1");
  });

  testWidgets("programmatic fiat refresh is marked while controller listeners run", (tester) async {
    final state = await showBox(tester, receiver: true);
    final updates = <bool>[];
    state.fiatAmountController.addListener(() => updates.add(state.isUpdatingFiatAmount));
    state.updateFiatAmount();
    expect(updates, [true]);
    state.fiatAmountController.text = "123";
    expect(updates, [true, false]);
  });

  testWidgets("same-fiat rate updates preserve a focused user's fiat text", (tester) async {
    final state = await showBox(tester, receiver: true);
    state.amountFocusNode.requestFocus();
    await tester.pump();
    state.fiatAmountController.text = "123.45";
    runInAction(() => conversion.value = "310.00");
    await tester.pump();
    expect(state.fiatAmountController.text, "123.45");
  });
}
