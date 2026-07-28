import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cake_wallet/new-ui/widgets/money/money_settings_cubit.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";

class FakeMoneySettingsCubit extends Cubit<MoneySettingsState> implements MoneySettingsCubit {
  FakeMoneySettingsCubit(super.initialState);

  void setState(MoneySettingsState state) => emit(state);
}

/// Visible, BTC shown as bitcoin (not base unit).
const _visibleBtc = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.bitcoin,
  displayMode: BalanceDisplayMode.fullBalance,
);

/// Hidden balance.
const _hiddenBtc = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.bitcoin,
  displayMode: BalanceDisplayMode.hiddenBalance,
);

/// Visible, satoshi mode -> BTC/BTCLN use base unit.
const _sats = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.satoshi,
  displayMode: BalanceDisplayMode.fullBalance,
);

/// Visible, LN-only satoshi mode -> only BTCLN uses base unit.
const _lnSats = MoneySettingsState(
  bitcoinAmountDisplayMode: BitcoinAmountDisplayMode.satoshiForLightning,
  displayMode: BalanceDisplayMode.fullBalance,
);

// --- Money fixtures --------------------------------------------------------
final _btc012 = Money.fromInt(12345678, CryptoCurrency.btc); // 0.12345678 BTC
final _btcTrailing = Money.fromInt(12000000, CryptoCurrency.btc); // 0.12 BTC
final _btcGrouping = Money.fromInt(123450000000, CryptoCurrency.btc); // 1234.5 BTC
final _xmrHalf = Money.fromInt(500000000000, CryptoCurrency.xmr); // 0.5 XMR
final _btclnAmount = Money.fromInt(12345678, CryptoCurrency.btcln); // 0.12345678 BTC (LN)

const _hidden = "●●●●●●";

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
  group("hidden amount", () {
    testWidgets("isHiddenAmount:true hides even when state is visible", (tester) async {
      await _pump(tester, MoneyText(_btc012, isHiddenAmount: true), _visibleBtc);

      expect(find.text(_hidden), findsOneWidget);
      expect(find.text("0.12345678 BTC"), findsNothing);
    });

    testWidgets("isHiddenAmount:false overrides a hidden state", (tester) async {
      await _pump(tester, MoneyText(_btc012, isHiddenAmount: false), _hiddenBtc);

      expect(find.text("0.12345678 BTC"), findsOneWidget);
      expect(find.text(_hidden), findsNothing);
    });

    testWidgets("isHiddenAmount:null falls back to state.isHidden (hidden)", (tester) async {
      await _pump(tester, MoneyText(_btc012), _hiddenBtc);

      expect(find.text(_hidden), findsOneWidget);
    });

    testWidgets("isHiddenAmount:null falls back to state.isHidden (visible)", (tester) async {
      await _pump(tester, MoneyText(_btc012), _visibleBtc);

      expect(find.text("0.12345678 BTC"), findsOneWidget);
      expect(find.text(_hidden), findsNothing);
    });
  });

  group("symbol vs precision", () {
    testWidgets("showSymbol:true appends the currency symbol", (tester) async {
      await _pump(tester, MoneyText(_btc012), _visibleBtc);

      expect(find.text("0.12345678 BTC"), findsOneWidget);
    });

    testWidgets("showSymbol:false omits the currency symbol", (tester) async {
      await _pump(tester, MoneyText(_btc012, showSymbol: false), _visibleBtc);

      expect(find.text("0.12345678"), findsOneWidget);
      expect(find.text("0.12345678 BTC"), findsNothing);
    });
  });

  group("withSymbolPrefix", () {
    test("defaults to false on the constructor", () {
      expect(MoneyText(_btc012).withSymbolPrefix, false);
    });

    test("defaults to false via optional", () {
      expect((MoneyText.optional(_btc012) as MoneyText).withSymbolPrefix, false);
    });

    testWidgets("ignored when showSymbol is false", (tester) async {
      await _pump(
        tester,
        MoneyText(_btc012, showSymbol: false, withSymbolPrefix: true),
        _visibleBtc,
      );

      expect(find.text("0.12345678"), findsOneWidget);
      expect(find.text("BTC 0.12345678"), findsNothing);
      expect(find.text("0.12345678 BTC"), findsNothing);
    });

    testWidgets("prefixes the symbol before the amount", (tester) async {
      await _pump(tester, MoneyText(_btc012, withSymbolPrefix: true), _visibleBtc);

      expect(find.text("BTC 0.12345678"), findsOneWidget);
    });

    testWidgets("prefixed amount is still localized (en_US grouping)", (tester) async {
      await _pump(tester, MoneyText(_btcGrouping, withSymbolPrefix: true), _visibleBtc);

      expect(find.text("BTC 1,234.5"), findsOneWidget);
    });

    testWidgets("prefixed amount respects an explicit de_DE locale", (tester) async {
      await _pump(
        tester,
        MoneyText(_btcGrouping, withSymbolPrefix: true, locale: const Locale("de", "DE")),
        _visibleBtc,
      );

      expect(find.text("BTC 1.234,5"), findsOneWidget);
    });

    testWidgets("prefixes the base-unit ticker (sats)", (tester) async {
      await _pump(
        tester,
        MoneyText(_btc012, withSymbolPrefix: true, useBaseUnit: true),
        _visibleBtc,
      );

      expect(find.text("sats 12,345,678"), findsOneWidget);
    });
  });

  group("base unit (useBaseUnit)", () {
    testWidgets("explicit useBaseUnit:true renders sats", (tester) async {
      await _pump(tester, MoneyText(_btc012, useBaseUnit: true), _visibleBtc);

      // 12345678 sats, localized grouping applied by withLocalSeperator.
      expect(find.text("12,345,678 sats"), findsOneWidget);
    });

    testWidgets("explicit useBaseUnit:false overrides a satoshi state", (tester) async {
      await _pump(tester, MoneyText(_btc012, useBaseUnit: false), _sats);

      expect(find.text("0.12345678 BTC"), findsOneWidget);
    });

    testWidgets("useBaseUnit:null -> state decides (BTC in satoshi mode -> sats)", (tester) async {
      await _pump(tester, MoneyText(_btc012), _sats);

      expect(find.text("12,345,678 sats"), findsOneWidget);
    });

    testWidgets("useBaseUnit:null -> state decides (BTC in bitcoin mode -> BTC)", (tester) async {
      await _pump(tester, MoneyText(_btc012), _visibleBtc);

      expect(find.text("0.12345678 BTC"), findsOneWidget);
    });

    testWidgets("non-BTC currency ignores satoshi mode", (tester) async {
      await _pump(tester, MoneyText(_xmrHalf), _sats);

      expect(find.text("0.5 XMR"), findsOneWidget);
    });

    testWidgets("LN-satoshi mode makes BTCLN use base unit", (tester) async {
      await _pump(tester, MoneyText(_btclnAmount), _lnSats);

      expect(find.text("12,345,678 sats"), findsOneWidget);
    });

    testWidgets("LN-satoshi mode leaves plain BTC untouched", (tester) async {
      await _pump(tester, MoneyText(_btc012), _lnSats);

      expect(find.text("0.12345678 BTC"), findsOneWidget);
    });
  });

  group("fractionalDigits & trimZeros", () {
    testWidgets("fractionalDigits truncates (does not round)", (tester) async {
      await _pump(tester, MoneyText(_btc012, fractionalDigits: 2), _visibleBtc);

      // 0.12345678 truncated to 2 digits -> 0.12 (NOT 0.13).
      expect(find.text("0.12 BTC"), findsOneWidget);
    });

    testWidgets("trimZeros:true (default) removes trailing zeros", (tester) async {
      await _pump(tester, MoneyText(_btcTrailing), _visibleBtc);

      expect(find.text("0.12 BTC"), findsOneWidget);
    });

    testWidgets("trimZeros:false keeps trailing zeros", (tester) async {
      await _pump(tester, MoneyText(_btcTrailing, trimZeros: false), _visibleBtc);

      expect(find.text("0.12000000 BTC"), findsOneWidget);
    });
  });

  group("locale & separators", () {
    testWidgets('default locale (en_US) uses "," grouping and "." decimal', (tester) async {
      await _pump(tester, MoneyText(_btcGrouping), _visibleBtc);

      expect(find.text("1,234.5 BTC"), findsOneWidget);
    });

    testWidgets("explicit de_DE locale swaps grouping/decimal separators", (tester) async {
      await _pump(
        tester,
        MoneyText(_btcGrouping, locale: const Locale("de", "DE")),
        _visibleBtc,
      );

      expect(find.text("1.234,5 BTC"), findsOneWidget);
    });
  });

  group("rebuild on cubit state change", () {
    testWidgets("re-renders when the settings state changes", (tester) async {
      final cubit = await _pump(tester, MoneyText(_btc012), _visibleBtc);
      expect(find.text("0.12345678 BTC"), findsOneWidget);

      cubit.setState(_hiddenBtc);
      await tester.pump();

      expect(find.text("0.12345678 BTC"), findsNothing);
      expect(find.text(_hidden), findsOneWidget);
    });
  });

  group("forwarding to the inner Text", () {
    testWidgets("passes through Text properties incl. semanticsIdentifier", (tester) async {
      await _pump(
        tester,
        MoneyText(
          _btc012,
          maxLines: 3,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 42),
          semanticsIdentifier: "via-ctor",
        ),
        _visibleBtc,
      );

      final text = tester.widget<Text>(
        find.descendant(of: find.byType(MoneyText), matching: find.byType(Text)),
      );

      expect(text.maxLines, 3);
      expect(text.textAlign, TextAlign.right);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.style?.fontSize, 42);
      expect(text.semanticsIdentifier, "via-ctor");
    });
  });

  group("MoneyText.optional", () {
    test("returns SizedBox.shrink for a null amount", () {
      final widget = MoneyText.optional(null);

      expect(widget, isA<SizedBox>());
      final box = widget as SizedBox;
      expect(box.width, 0.0);
      expect(box.height, 0.0);
    });

    test("returns a MoneyText for a non-null amount", () {
      expect(MoneyText.optional(_btc012), isA<MoneyText>());
    });

    test("forwards money-specific parameters to MoneyText", () {
      final widget = MoneyText.optional(
        _btc012,
        showSymbol: false,
        fractionalDigits: 3,
        trimZeros: false,
        isHiddenAmount: true,
        useBaseUnit: true,
        withSymbolPrefix: true,
      ) as MoneyText;

      expect(widget.showSymbol, false);
      expect(widget.fractionalDigits, 3);
      expect(widget.trimZeros, false);
      expect(widget.isHiddenAmount, true);
      expect(widget.useBaseUnit, true);
      expect(widget.withSymbolPrefix, true);
    });

    testWidgets("renders identically to a direct MoneyText", (tester) async {
      await _pump(tester, MoneyText.optional(_btc012), _visibleBtc);

      expect(find.byType(MoneyText), findsOneWidget);
      expect(find.text("0.12345678 BTC"), findsOneWidget);
    });

    test(
      "forwards semanticsIdentifier to MoneyText",
          () {
        final widget = MoneyText.optional(_btc012, semanticsIdentifier: "sid") as MoneyText;

        expect(widget.semanticsIdentifier, "sid");
      },
    );
  });
}
