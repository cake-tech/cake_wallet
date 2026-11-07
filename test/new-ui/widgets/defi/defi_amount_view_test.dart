import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_amount_view.dart";
import "package:cake_wallet/new-ui/widgets/floating_amount_input.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeMoneySettingsCubit extends Cubit<MoneySettingsState> implements MoneySettingsCubit {
  _FakeMoneySettingsCubit()
      : super(
          const MoneySettingsState(
            bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.bitcoin,
            displayMode: BalanceDisplayMode.fullBalance,
          ),
        );
}

Money _eth(String amount) => Money.parse(amount, CryptoCurrency.eth);

Money _usd(String amount) => Money.parse(amount, FiatCurrency.usd);

ExchangeRate _rate(String usd) => ExchangeRate(base: CryptoCurrency.eth, quote: _usd(usd));

Matcher _leastWorth(ExchangeRate rate, Money fiat) => predicate<Money>(
      (eth) =>
          rate.convert(eth) == fiat && rate.convert(eth - Money(BigInt.one, eth.currency)) < fiat,
      "the least ETH worth $fiat",
    );

void main() {
  Money? continuedAmount;
  bool? continuedMax;

  setUp(() {
    continuedAmount = null;
    continuedMax = null;
  });

  Future<void> pumpView(WidgetTester tester, {ExchangeRate? rate, Money? max}) => tester.pumpWidget(
        BlocProvider<MoneySettingsCubit>(
          create: (_) => _FakeMoneySettingsCubit(),
          child: MaterialApp(
            localizationsDelegates: localizationDelegates,
            supportedLocales: S.delegate.supportedLocales,
            home: Scaffold(
              body: DefiAmountView(
                maxAmount: max ?? _eth("1"),
                maxLabel: "Max",
                maxChipLabel: "Max",
                hint: "Min: 0.01 ETH",
                fiatRate: rate,
                onContinue: (amount, {required isMax}) {
                  continuedAmount = amount;
                  continuedMax = isMax;
                },
              ),
            ),
          ),
        ),
      );

  // the sheet's close button is a ModernButton too
  final switchButton = find.byWidgetPredicate(
    (widget) => widget is ModernButton && widget.svgPath == "assets/new-ui/switch.svg",
  );

  Currency inputCurrency(WidgetTester tester) =>
      tester.widget<FloatingAmountInput>(find.byType(FloatingAmountInput)).currency;

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField), text);
    await tester.pump();
  }

  Future<void> tapSwitch(WidgetTester tester) async {
    await tester.tap(switchButton);
    await tester.pump();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text("Continue"));
    await tester.pump();
  }

  testWidgets("a typed fiat amount switches to ETH and keeps its exact value", (tester) async {
    final rate = _rate("2269.38");
    await pumpView(tester, rate: rate);
    expect(inputCurrency(tester), FiatCurrency.usd);

    await type(tester, "25");
    await tapSwitch(tester);

    expect(inputCurrency(tester), CryptoCurrency.eth);
    await tapContinue(tester);
    expect(continuedAmount, _leastWorth(rate, _usd("25")));
    expect(continuedMax, isFalse);
  });

  testWidgets("switching and rate updates keep the minimum stake exact", (tester) async {
    await pumpView(tester, rate: _rate("2269.38"));
    await tapSwitch(tester);
    await type(tester, "0.01");

    await tapSwitch(tester);
    expect(inputCurrency(tester), FiatCurrency.usd);

    await pumpView(tester, rate: _rate("2300"));
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, "23");

    await tapSwitch(tester);

    await tapContinue(tester);
    expect(continuedAmount, _eth("0.01"));
  });

  testWidgets("an edit after a switch is used as typed", (tester) async {
    await pumpView(tester, rate: _rate("2269.38"));
    await type(tester, "25");
    await tapSwitch(tester);

    await type(tester, "0.02");
    await tapContinue(tester);
    expect(continuedAmount, _eth("0.02"));
  });

  testWidgets("Max stays exact across a switch", (tester) async {
    final max = _eth("0.123456789012345678");
    await pumpView(tester, rate: _rate("2000"), max: max);
    await tester.tap(find.text("Max"));
    await tester.pump();

    await tapSwitch(tester);
    expect(inputCurrency(tester), CryptoCurrency.eth);

    await tapContinue(tester);
    expect(continuedAmount, max);
    expect(continuedMax, isTrue);
  });

  testWidgets("without a fiat rate the amount is entered in ETH", (tester) async {
    await pumpView(tester);
    await type(tester, "0.02");

    await tapContinue(tester);
    expect(continuedAmount, _eth("0.02"));
  });
}
