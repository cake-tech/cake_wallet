import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/new-ui/widgets/money/currency_symbol_text.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";

class FakeMoneySettingsCubit extends Cubit<MoneySettingsState> implements MoneySettingsCubit {
  FakeMoneySettingsCubit(super.initialState);

  void setState(MoneySettingsState state) => emit(state);
}

const _bitcoinMode = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.bitcoin,
  displayMode: BalanceDisplayMode.fullBalance,
);

const _satoshiMode = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.satoshi,
  displayMode: BalanceDisplayMode.fullBalance,
);

const _lnSatoshiMode = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.satoshiForLightning,
  displayMode: BalanceDisplayMode.fullBalance,
);

/// A non-BTC currency whose symbol exceeds the 8-char cap. `raw: -1` keeps it
/// distinct from every real currency, so it never counts as BTC/BTCLN.
const _longSymbol = CryptoCurrency(title: "SUPERLONGTOKEN", name: "superlongtoken", decimals: 8);

Future<FakeMoneySettingsCubit> _pump(
    WidgetTester tester,
    Widget child,
    MoneySettingsState state,
    ) async {
  final cubit = FakeMoneySettingsCubit(state);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<MoneySettingsCubit>.value(
        value: cubit,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  return cubit;
}

void main() {
  group("useBaseUnit == null (follows settings)", () {
    testWidgets("BTC in satoshi mode -> sats", (tester) async {
      await _pump(tester, const CurrencySymbolText(CryptoCurrency.btc), _satoshiMode);

      expect(find.text("sats"), findsOneWidget);
    });

    testWidgets("BTC in bitcoin mode -> BTC", (tester) async {
      await _pump(tester, const CurrencySymbolText(CryptoCurrency.btc), _bitcoinMode);

      expect(find.text("BTC"), findsOneWidget);
    });

    testWidgets("non-BTC currency ignores satoshi mode", (tester) async {
      await _pump(tester, const CurrencySymbolText(CryptoCurrency.xmr), _satoshiMode);

      expect(find.text("XMR"), findsOneWidget);
    });

    testWidgets("BTCLN in LN-satoshi mode -> sats", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.btcln),
        _lnSatoshiMode,
      );

      expect(find.text("sats"), findsOneWidget);
    });

    testWidgets("BTCLN in bitcoin mode -> BTC", (tester) async {
      await _pump(tester, const CurrencySymbolText(CryptoCurrency.btcln), _bitcoinMode);

      // BTCLN's title/symbol is "BTC".
      expect(find.text("BTC"), findsOneWidget);
    });
  });

  group("useBaseUnit == true (force base unit where supported)", () {
    testWidgets("BTC -> sats regardless of settings", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.btc, useBaseUnit: true),
        _bitcoinMode, // settings say bitcoin, but override wins
      );

      expect(find.text("sats"), findsOneWidget);
    });

    testWidgets("BTCLN -> sats", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.btcln, useBaseUnit: true),
        _bitcoinMode,
      );

      expect(find.text("sats"), findsOneWidget);
    });

    testWidgets("non-BTC currency keeps its symbol even when forced", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.xmr, useBaseUnit: true),
        _satoshiMode,
      );

      expect(find.text("XMR"), findsOneWidget);
    });
  });

  group("useBaseUnit == false (always the symbol)", () {
    testWidgets("BTC -> BTC even in satoshi mode", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.btc, useBaseUnit: false),
        _satoshiMode,
      );

      expect(find.text("BTC"), findsOneWidget);
      expect(find.text("sats"), findsNothing);
    });

    testWidgets("BTCLN -> BTC even in LN-satoshi mode", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.btcln, useBaseUnit: false),
        _lnSatoshiMode,
      );

      expect(find.text("BTC"), findsOneWidget);
      expect(find.text("sats"), findsNothing);
    });

    testWidgets("non-BTC currency -> symbol", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.xmr, useBaseUnit: false),
        _bitcoinMode,
      );

      expect(find.text("XMR"), findsOneWidget);
    });
  });

  group("symbol formatting", () {
    testWidgets("caps symbols longer than 8 characters", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(_longSymbol, useBaseUnit: false),
        _bitcoinMode,
      );

      // "SUPERLONGTOKEN" -> first 8 chars.
      expect(find.text("SUPERLON"), findsOneWidget);
    });
  });

  group("rebuild on cubit state change", () {
    testWidgets("re-renders the symbol when settings change", (tester) async {
      final cubit = await _pump(
        tester,
        const CurrencySymbolText(CryptoCurrency.btc),
        _bitcoinMode,
      );
      expect(find.text("BTC"), findsOneWidget);

      cubit.setState(_satoshiMode);
      await tester.pump();

      expect(find.text("BTC"), findsNothing);
      expect(find.text("sats"), findsOneWidget);
    });
  });

  group("forwarding to the inner Text", () {
    testWidgets("passes through Text properties incl. semanticsIdentifier", (tester) async {
      await _pump(
        tester,
        const CurrencySymbolText(
          CryptoCurrency.btc,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.fade,
          style: TextStyle(fontSize: 18),
          semanticsIdentifier: "currency-symbol",
        ),
        _bitcoinMode,
      );

      final text = tester.widget<Text>(
        find.descendant(of: find.byType(CurrencySymbolText), matching: find.byType(Text)),
      );

      expect(text.maxLines, 2);
      expect(text.textAlign, TextAlign.center);
      expect(text.overflow, TextOverflow.fade);
      expect(text.style?.fontSize, 18);
      expect(text.semanticsIdentifier, "currency-symbol");
    });
  });
}
